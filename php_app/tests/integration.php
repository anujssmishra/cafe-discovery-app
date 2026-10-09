<?php
declare(strict_types=1);

// This command is destructive only to an explicitly selected disposable local test DB.
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
$host=getenv('DB_HOST')?:'127.0.0.1';
$name=getenv('DB_NAME')?:'';
if (getenv('APP_ENV')!=='test' || !preg_match('/^[A-Za-z0-9_]+_test$/D',$name)
    || !in_array($host,['127.0.0.1','localhost','::1','mysql'],true)
    || $argc!==2 || $argv[1]!=='--allow-reset') {
    fwrite(STDERR,"Refusing reset. Require APP_ENV=test, local/mysql DB_HOST, DB_NAME ending _test and --allow-reset.\n");
    exit(2);
}
$root=dirname(__DIR__);
require_once $root.'/includes/db.php';
require_once $root.'/includes/seed.php';
require_once $root.'/scripts/schema_helpers.php';
require_once $root.'/includes/catalogue.php';
$checks=0; $servers=[];
function check(bool $condition,string $label):void {
    global $checks;
    if(!$condition){throw new RuntimeException($label);}
    $checks++;
}
function rows(PDO $pdo):array {
    $result=[];
    foreach(['area','cafe','cafe_offering']as$table){
        $result[$table]=$pdo->query('SELECT * FROM '.$table.' ORDER BY id')->fetchAll();
    }
    return $result;
}
function cli(array $args,array $overrides=[]):array {
    global $root;
    $process=proc_open(array_merge([PHP_BINARY],$args),[1=>['pipe','w'],2=>['pipe','w']],$pipes,$root,array_merge(getenv(),$overrides));
    if(!is_resource($process)){throw new RuntimeException('Cannot start CLI check');}
    $output=stream_get_contents($pipes[1]).stream_get_contents($pipes[2]);
    fclose($pipes[1]); fclose($pipes[2]);
    return[proc_close($process),$output];
}
function rejected(PDO $pdo,string $sql,array $params,int $code,string $label):void {
    try{$pdo->prepare($sql)->execute($params);}
    catch(PDOException $error){check(($error->errorInfo[1]??null)===$code,$label.' constraint error code');return;}
    throw new RuntimeException('Constraint accepted invalid data: '.$label);
}
function server(array $overrides=[]):string{
    global $servers,$root;
    $socket=stream_socket_server('tcp://127.0.0.1:0',$errno,$error);$address=stream_socket_get_name($socket,false);fclose($socket);
    $log=tmpfile();
    $p=proc_open([PHP_BINARY,'-d','display_errors=1','-S',$address,'-t',$root.'/public',$root.'/public/router.php'],[0=>['pipe','r'],1=>$log,2=>$log],$pipes,$root,array_merge(getenv(),$overrides));
    fclose($pipes[0]);$servers[]=[$p,$log];
    for($i=0;$i<50;$i++){ $c=@stream_socket_client('tcp://'.$address,$errno,$error,0.1);if($c){fclose($c);return 'http://'.$address;}usleep(100000);}
    throw new RuntimeException('Server startup timeout');
}
function response(string $url,string $method='GET'):array{
    $body=file_get_contents($url,false,stream_context_create(['http'=>['method'=>$method,'ignore_errors'=>true,'follow_location'=>0,'timeout'=>10]]));
    if($body===false){throw new RuntimeException('No HTTP response');}
    preg_match('/^HTTP\/\S+\s+(\d+)/',$http_response_header[0]??'',$match);return[(int)($match[1]??0),$body];
}
register_shutdown_function(static function():void{global $servers;foreach($servers as[$p,$log]){proc_terminate($p);proc_close($p);fclose($log);}});

try {
    $pdo=db_connect();
    foreach (['cafe_offering','cafe','area'] as $table) { $pdo->exec('DROP TABLE IF EXISTS ' . $table); }
    schema_apply($pdo); check(!$pdo->getAttribute(PDO::ATTR_EMULATE_PREPARES), 'Native prepare setting');
    $pdo->exec("INSERT INTO area (name,slug,city) VALUES ('Unrelated','unrelated','Test only')"); $area = (int) $pdo->lastInsertId();
    $unrelated = '90000000-0000-4000-8000-000000000099';
    $pdo->prepare("INSERT INTO cafe (id,name,area_id,address,source,checked_on) VALUES (?,'Unrelated',?,'Test address','https://example.test/evidence','2018-03-02')")->execute([$unrelated,$area]);
    $pdo->prepare("INSERT INTO cafe_offering (cafe_id,drink_type,price,source,checked_on) VALUES (?,'tea',0,'https://example.test/menu','2018-03-02')")->execute([$unrelated]);
    $unrelatedBefore = rows($pdo); $stats = seed_demo($pdo);
    check($stats['areas_inserted'] === 2 && $stats['cafes_inserted'] === 8 && $stats['offerings_inserted'] === 16, 'Initial seed counts');
    $expectedIds = ['b1833e2a-f772-50cc-8dfc-b08eb028fe04','c7876dda-d0a2-58fb-9675-3bd6a21184bb','ddb9d09e-8e1e-5fdc-87d0-24de206a7da2','1be94070-8833-5815-8876-f398ba078928','aeabd403-b807-50c2-94a8-8ec8e16f6b70','0e05e5ef-6158-5e80-a9e7-9f28dfae5f7c','7d3e7ccf-168c-5f30-a21f-8b914520c4b9','2774ea7e-9968-5f29-b258-c62d4e5ed0ab'];
    sort($expectedIds); check($pdo->query('SELECT id FROM cafe WHERE is_demo=1 ORDER BY id')->fetchAll(PDO::FETCH_COLUMN) === $expectedIds, 'All independently recorded legacy UUIDs');
    $seeded = rows($pdo); foreach ($unrelatedBefore as $table=>$records) { foreach ($records as $row) { check(in_array($row,$seeded[$table],true), 'Unrelated ' . $table); }}
    check((int)$pdo->query('SELECT COUNT(*) FROM cafe WHERE is_demo=1 AND (checked_on IS NOT NULL OR brand_count_checked_on IS NOT NULL OR independence_checked_on IS NOT NULL)')->fetchColumn()===0,'New cafe evidence unknown');
    check((int)$pdo->query('SELECT COUNT(*) FROM cafe_offering o JOIN cafe c ON c.id=o.cafe_id WHERE c.is_demo=1 AND o.checked_on IS NOT NULL')->fetchColumn()===0,'New offering evidence unknown');
    $id=$expectedIds[0];
    $pdo->prepare("UPDATE cafe SET checked_on='2020-04-06',source='https://example.test/archive',brand_count_checked_on='2019-10-11',brand_count_source='https://example.test/brand',independence_checked_on='2019-09-12',independence_source='https://example.test/owner',is_active=0 WHERE id=?")->execute([$id]);
    $pdo->prepare("UPDATE cafe_offering SET checked_on='2017-02-03',source='https://example.test/archive-menu' WHERE cafe_id=?")->execute([$id]);
    $beforeRepeat=rows($pdo); for($i=0;$i<2;$i++){ $again=seed_demo($pdo); check($again['cafes_inserted']===0&&$again['cafes_existing']===8,'Repeat insertion counts'); check(rows($pdo)===$beforeRepeat,'Repeat preserves all rows IDs historical evidence flags'); }
    $pdo->exec('ALTER TABLE cafe DROP CHECK chk_cafe_uuid'); $pdo->exec('ALTER TABLE cafe ALTER CHECK chk_cafe_active NOT ENFORCED');
    schema_apply($pdo); check(rows($pdo)===$beforeRepeat,'Additive schema repair preserves data');
    try { $pdo->prepare('UPDATE cafe SET is_active=2 WHERE id=?')->execute([$unrelated]); throw new RuntimeException('Disabled check not restored'); }
    catch(PDOException $error){check(($error->errorInfo[1]??null)===3819,'Schema repair re-enforces CHECK');}
    $rollbackId='c7876dda-d0a2-58fb-9675-3bd6a21184bb'; $pdo->prepare('DELETE FROM cafe WHERE id=?')->execute([$rollbackId]); $beforeFailure=rows($pdo);
    check((int)$pdo->query('SELECT COUNT(*) FROM cafe_offering WHERE price=170')->fetchColumn()===0,'Fault constraint can be added before seed');
    $pdo->exec("ALTER TABLE cafe_offering ADD CONSTRAINT qa_manual_fail CHECK (price IS NULL OR price <> 170)");
    $failed=false; $openAfterFailure=false;
    try { seed_demo($pdo); }
    catch(PDOException $error) { $failed=($error->errorInfo[1]??null)===3819&&str_contains($error->getMessage(),'qa_manual_fail'); }
    finally {
        $openAfterFailure=$pdo->inTransaction();
        if($openAfterFailure){$pdo->rollBack();}
        $pdo->exec('ALTER TABLE cafe_offering DROP CHECK qa_manual_fail');
    }
    check($failed&&!$openAfterFailure,'Exact injected failure rolled back before DDL cleanup'); check(rows($pdo)===$beforeFailure,'Full rollback after preceding cafe insert');
    seed_demo($pdo); check((int)$pdo->query('SELECT COUNT(*) FROM cafe WHERE is_demo=1')->fetchColumn()===8,'Recovery');
    $beforeCaller=rows($pdo); $pdo->beginTransaction(); $refused=false; try{seed_demo($pdo);}catch(RuntimeException $error){$refused=true;}
    check($refused&&$pdo->inTransaction(),'Caller transaction ownership'); $pdo->rollBack(); check(rows($pdo)===$beforeCaller,'Caller transaction rows preserved');
    $collisionId='b1833e2a-f772-50cc-8dfc-b08eb028fe04'; $pdo->prepare('DELETE FROM cafe WHERE id=?')->execute([$collisionId]);
    $pdo->prepare("INSERT INTO cafe (id,name,area_id,address,is_demo) VALUES (?,'Reserved unrelated',?,'Test only',0)")->execute([$collisionId,$area]);
    $beforeCollision=rows($pdo); $refused=false; try{seed_demo($pdo);}catch(RuntimeException $error){$refused=true;}
    check($refused&&!$pdo->inTransaction(),'Unrelated reserved UUID refused'); check(rows($pdo)===$beforeCollision,'UUID collision preserves unrelated data');

    // Native prepares must reproduce the old duplicated-placeholder failure.
    try {
        $statement=$pdo->prepare('SELECT :checked AS first_checked, :checked AS second_checked');
        $statement->execute(['checked'=>'2020-04-06']);
        throw new RuntimeException('Repeated placeholder unexpectedly accepted');
    } catch(PDOException $error){check($error->getCode()==='HY093','Native duplicate-placeholder regression reproduced');}

    // Exercise the public CLI, including guarded refusal before connecting.
    $beforeCli=rows($pdo);
    [$code]=cli([$root.'/scripts/seed.php','--demo'],['APP_ENV'=>'production','DEMO_MODE'=>'false']);
    check($code===1&&rows($pdo)===$beforeCli,'Production CLI seed refusal preserves rows');
    [$code]=cli([$root.'/scripts/seed.php']);
    check($code===2&&rows($pdo)===$beforeCli,'CLI seed requires explicit --demo');
    // Remove the reserved collision fixture before checking successful CLI repeats.
    $pdo->prepare('DELETE FROM cafe WHERE id=?')->execute([$collisionId]);
    [$code,$output]=cli([$root.'/scripts/seed.php','--demo']);
    check($code===0,'CLI seed success: '.$output);
    $beforeCli=rows($pdo);
    for($run=0;$run<2;$run++){
        [$code,$output]=cli([$root.'/scripts/seed.php','--demo']);
        check($code===0&&rows($pdo)===$beforeCli,'CLI repeat seed preserves full snapshot: '.$output);
    }
    [$code,$output]=cli([$root.'/scripts/schema.php','--apply']);
    check($code===0&&rows($pdo)===$beforeCli,'CLI schema repeat preserves snapshot: '.$output);

    // Check exact MySQL errors, rather than accepting arbitrary syntax/connection failures.
    rejected($pdo,'UPDATE cafe_offering SET price=-1 WHERE cafe_id=?',[$unrelated],3819,'Price');
    rejected($pdo,"UPDATE cafe_offering SET drink_type='not-a-drink' WHERE cafe_id=?",[$unrelated],3819,'Drink');
    rejected($pdo,"UPDATE cafe_offering SET currency='12!' WHERE cafe_id=?",[$unrelated],3819,'Currency');
    rejected($pdo,'UPDATE cafe SET latitude=91,longitude=80 WHERE id=?',[$unrelated],3819,'Latitude');
    rejected($pdo,'UPDATE cafe SET latitude=10,longitude=NULL WHERE id=?',[$unrelated],3819,'Coordinate pair');
    rejected($pdo,'UPDATE cafe SET brand_location_count=0 WHERE id=?',[$unrelated],3819,'Brand count');
    rejected($pdo,"UPDATE cafe SET independence_status='invented' WHERE id=?",[$unrelated],3819,'Ownership');
    rejected($pdo,'UPDATE cafe SET is_active=2 WHERE id=?',[$unrelated],3819,'Active flag');
    rejected($pdo,'UPDATE cafe SET is_demo=2 WHERE id=?',[$unrelated],3819,'Demo flag');
    rejected($pdo,'UPDATE cafe SET area_id=2147483647 WHERE id=?',[$unrelated],1452,'Area FK');
    rejected($pdo,'UPDATE cafe SET id=? WHERE id=?',['malformed-id',$unrelated],3819,'UUID');

    $pdo->exec("INSERT INTO area (name,slug,city) VALUES ('QA active','qa-active','Test only')");
    $area=(int)$pdo->lastInsertId();
    $pdo->exec("INSERT INTO area (name,slug,city,is_active) VALUES ('QA inactive','qa-inactive','Test only',0)");
    $hiddenArea=(int)$pdo->lastInsertId();
    $insert=$pdo->prepare('INSERT INTO cafe (id,name,area_id,address,is_active,is_demo) VALUES (?,?,?,?,?,0)');
    $ids=[];
    for($n=0;$n<26;$n++){ $id=sprintf('90000000-0000-4000-8000-%012d',$n);$ids[]=$id;$insert->execute([$id,sprintf('QA Match %02d',$n),$area,'Test address',1]);}
    $inactive='90000000-0000-4000-8000-000000000100';$hidden='90000000-0000-4000-8000-000000000101';
    $escaped='90000000-0000-4000-8000-000000000102';$evidence='90000000-0000-4000-8000-000000000103';
    $insert->execute([$inactive,'QA Match inactive',$area,'Hidden',0]);$insert->execute([$hidden,'QA Match hidden',$hiddenArea,'Hidden',1]);
    $insert->execute([$escaped,'QA 50%_! <script>alert("x")</script>',$area,'<img src=x onerror=alert(1)>',1]);
    $insert->execute([$evidence,'QA Legacy evidence',$area,'Test only',1]);
    $insert->execute(['90000000-0000-4000-8000-000000000104','QA wildcard decoy!',$area,'Test only',1]);
    $tieLow='90000000-0000-4000-8000-000000000105';$tieHigh='90000000-0000-4000-8000-000000000106';
    $insert->execute([$tieHigh,'QA Tie',$area,'Test only',1]);$insert->execute([$tieLow,'QA Tie',$area,'Test only',1]);
    $pdo->prepare("UPDATE cafe SET independence_status='verified_independent',independence_source='Web research',independence_checked_on=CURRENT_DATE(),website='javascript:alert(1)' WHERE id=?")->execute([$evidence]);
    $beforeEvidence=$pdo->query("SELECT * FROM cafe WHERE id='".$evidence."'")->fetch();
    $pdo->prepare("INSERT INTO cafe_offering (cafe_id,drink_type,price,currency,source) VALUES (?,'tea',0,'INR','Menu')")->execute([$escaped]);
    $filters=['q'=>'QA Match','area'=>'qa-active','page'=>1];$first=catalogue_page($pdo,$filters,true);
    check($first['pagination']['total']===26&&$first['pagination']['pages']===3&&count($first['cafes'])===12,'Combined filters first page');
    check(array_column($first['cafes'],'id')===array_slice($ids,0,12),'Name ordering');
    check(array_column(catalogue_page($pdo,array_replace($filters,['page'=>2]),true)['cafes'],'id')===array_slice($ids,12,12),'Second page');
    $last=catalogue_page($pdo,array_replace($filters,['page'=>1000000000]),true);check($last['pagination']['page']===3&&array_column($last['cafes'],'id')===array_slice($ids,24),'Page clamp');
    $empty=catalogue_page($pdo,['q'=>'QA Match','area'=>'unknown-area','page'=>5],true);check($empty['cafes']===[]&&$empty['pagination']['page']===1,'Empty page bounded');
    foreach(['%_!','%','_']as$q){check(array_column(catalogue_page($pdo,['q'=>$q,'area'=>'qa-active','page'=>1],true)['cafes'],'id')===[$escaped],'Literal wildcard '.$q);}
    check(array_column(catalogue_page($pdo,['q'=>'QA Tie','area'=>'qa-active','page'=>1],true)['cafes'],'id')===[$tieLow,$tieHigh],'Equal name ID tie-break');
    foreach([$inactive,$hidden,'90000000-0000-4000-8000-999999999999']as$id){check(catalogue_detail($pdo,$id,true)===false,'Inactive/missing detail');}
    check(catalogue_detail($pdo,'c7876dda-d0a2-58fb-9675-3bd6a21184bb',true)!==false&&catalogue_detail($pdo,'c7876dda-d0a2-58fb-9675-3bd6a21184bb',false)===false,'Active demo visibility');
    $base=server();
    [$status,$body]=response($base.'/?q=QA%20Match&area=qa-active');check($status===200&&str_contains($body,'QA Match 00')&&!str_contains($body,'QA Match 12'),'HTTP first page');
    check(str_contains($body,'q=QA%20Match&amp;area=qa-active&amp;page=2'),'HTTP filters preserved in pagination');
    [$status,$body]=response($base.'/?q=QA%20Match&area=qa-active&page=2');check($status===200&&str_contains($body,'QA Match 12')&&!str_contains($body,'QA Match 00'),'HTTP second page');
    foreach(['q%5B%5D=bad','area%5B%5D=bad','page%5B%5D=bad','q=%00bad','page=-2','area=..%2Fprivate','q='.str_repeat('a',181)]as$q){
        [$status,$body]=response($base.'/?'.$q);check($status===400&&!preg_match('/Warning:|Fatal error:|Notice:|PDOException|SQLSTATE/i',$body),'HTTP malformed safe400');
    }
    [$status,$body]=response($base.'/?q=QA%20Match&area=unknown-area');check($status===200&&preg_match('/no café|no cafe|no results/i',$body)===1,'HTTP empty message');
    foreach([$inactive,$hidden,'90000000-0000-4000-8000-999999999999','not-a-uuid']as$id){[$status,$body]=response($base.'/cafes/'.$id.'/');check($status===404&&!preg_match('/Warning:|Fatal error:|Notice:/i',$body),'HTTP safe404');}
    [$status,$body]=response($base.'/cafes/'.$escaped.'/');check($status===200&&str_contains($body,'&lt;script&gt;')&&!str_contains($body,'<script>alert("x")</script>')&&str_contains($body,'&lt;img')&&!str_contains($body,'<img src=x'),'Escaped detail');check(str_contains(strip_tags($body),'INR 0.00'),'Zero price');
    [$status,$body]=response($base.'/cafes/'.$evidence.'/');check($status===200&&preg_match('/>\s*(?:Verified )?Independent\s*</i',$body)!==1&&preg_match('/unknown|no documented/i',$body)===1,'Unsubstantiated ownership unknown');
    check(!str_contains($body,'href="javascript:'),'Unsafe website omitted');
    check($pdo->query("SELECT * FROM cafe WHERE id='".$evidence."'")->fetch()===$beforeEvidence,'Rendering preserves complete evidence row');
    [$status,$body]=response($base.'/','HEAD');check($status===200&&$body==='','HEAD');
    [$status,$body]=response($base.'/','POST');check($status===405,'Method405');
    $plain=server(['DEMO_MODE'=>'false']);[$status,$body]=response($plain.'/?q=Ink');check($status===200&&!str_contains($body,'Demo Ink Cup')&&!str_contains($body,'Demo Paper Quarter'),'Demo catalogue and areas hidden');
    [$status,$body]=response($plain.'/cafes/c7876dda-d0a2-58fb-9675-3bd6a21184bb/');check($status===404,'Demo HTTP detail hidden');
    [$status,$body]=response($plain.'/?q=QA%20Match');check($status===200&&str_contains($body,'QA Match 00'),'Non-demo catalogue works');
    $bad=server(['DB_USER'=>'intentionally_missing_user','DB_PASS'=>'invalid-test-only']);[$status,$body]=response($bad.'/');
    check($status===503&&!preg_match('/SQLSTATE|PDOException|Stack trace|intentionally_missing_user|invalid-test-only|Access denied|\.php on line/i',$body),'Generic DB error');
    foreach($servers as[$p,$log]){fflush($log);rewind($log);check(!preg_match('/PHP (?:Warning|Fatal error|Notice):/',stream_get_contents($log)),'No PHP warning/fatal in HTTP logs');}

    $prefix=server(['APP_BASE_PATH'=>'/catalogue']);
    [$status,$body]=response($prefix.'/catalogue/');
    check($status===200&&str_contains($body,'/catalogue/static/site.css')&&str_contains($body,'/catalogue/cafes/'),'Subdirectory URLs');
    [$status]=response($prefix.'/catalogue/static/site.css'); check($status===200,'Subdirectory CSS');
    [$status]=response($prefix.'/catalogue/cafes/'.$escaped.'/'); check($status===200,'Subdirectory detail');
    foreach(['/scripts/seed.php','/.env','/includes/config.php','/router.php']as$path){
        [$status]=response($base.$path); check($status===404,'Nonpublic endpoint inaccessible: '.$path);
    }
    [$status,$body]=response($base.'/static/site.css'); check($status===200&&str_contains($body,'@media'),'Responsive CSS');
    [$status,$body]=response($base.'/about/'); check($status===200&&str_contains($body,'café'),'About page');
    [$status,$body]=response($base.'/?q=QA%20Match&area=qa-active&page='.str_repeat('9',100));
    check($status===200&&str_contains($body,'QA Match 25'),'Huge HTTP page bounded');
    fwrite(STDOUT,'MySQL integration checks passed: '.$checks.'. PHP '.PHP_VERSION.', MySQL '.$pdo->getAttribute(PDO::ATTR_SERVER_VERSION).".\n");
} catch(Throwable $error) {
    fwrite(STDERR,'FAIL after '.$checks.': '.$error->getMessage()."\n");
    exit(1);
}
