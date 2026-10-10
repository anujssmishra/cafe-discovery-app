<?php
declare(strict_types=1);

if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
$actual=dirname(__DIR__);
$temporary=sys_get_temp_dir().'/cafe-shared-package-'.bin2hex(random_bytes(8));
$source=$temporary.'/source';
$checks=0;$exitCode=0;
// Independent expected archive paths: protect the existing apex website.
$files=[
    'cafe_app/public_html/index.php'=>'public/index.php',
    'cafe_app/public_html/.htaccess'=>'public/.htaccess',
    'cafe_app/public_html/static/site.css'=>'public/static/site.css',
    'cafe_app/config/local.example.php'=>'config/local.example.php',
    'cafe_app/schema/schema.sql'=>'schema/schema.sql',
    'cafe_app/schema/README.md'=>'schema/README.md',
    'cafe_app/scripts/schema.php'=>'scripts/schema.php',
    'cafe_app/scripts/schema_helpers.php'=>'scripts/schema_helpers.php',
    'cafe_app/includes/config.php'=>'includes/config.php',
    'cafe_app/includes/db.php'=>'includes/db.php',
    'cafe_app/includes/request.php'=>'includes/request.php',
    'cafe_app/includes/catalogue.php'=>'includes/catalogue.php',
    'cafe_app/includes/web.php'=>'includes/web.php',
    'cafe_app/templates/header.php'=>'templates/header.php',
    'cafe_app/templates/footer.php'=>'templates/footer.php',
    'cafe_app/templates/catalogue.php'=>'templates/catalogue.php',
    'cafe_app/templates/cafe_detail.php'=>'templates/cafe_detail.php',
    'cafe_app/templates/about.php'=>'templates/about.php',
    'cafe_app/templates/error.php'=>'templates/error.php',
    'cafe_app/templates/_evidence.php'=>'templates/_evidence.php',
    'public_html/cafes/index.php'=>'deploy/shared/index.php',
    'public_html/cafes/.htaccess'=>'deploy/shared/.htaccess',
    'public_html/cafes/static/site.css'=>'public/static/site.css',
];
function shared_package_check(bool $condition,string $label):void{
    global $checks;if(!$condition){throw new RuntimeException($label);}$checks++;
}
function shared_package_command(array $arguments):array{
    global $source;
    $process=proc_open(array_merge([PHP_BINARY,$source.'/scripts/package.php'],$arguments),[1=>['pipe','w'],2=>['pipe','w']],$pipes,$source);
    if(!is_resource($process)){throw new RuntimeException('Cannot start shared package command');}
    $out=stream_get_contents($pipes[1]);$err=stream_get_contents($pipes[2]);fclose($pipes[1]);fclose($pipes[2]);
    return[proc_close($process),$out.$err];
}
function shared_package_php(string $code,array $environment=[]):array{
    $process=proc_open([PHP_BINARY,'-d','display_errors=1','-d','log_errors=0','-r',$code],[1=>['pipe','w'],2=>['pipe','w']],$pipes,null,$environment===[]?null:$environment);
    if(!is_resource($process)){throw new RuntimeException('Cannot start shared PHP probe');}
    $out=stream_get_contents($pipes[1]);$err=stream_get_contents($pipes[2]);fclose($pipes[1]);fclose($pipes[2]);
    return[proc_close($process),$out,$err];
}
function shared_package_config(string $deployment,?string $explicit=null):array{
    $environment=getenv();
    foreach(['APP_CONFIG_FILE','APP_ENV','DEMO_MODE','APP_BASE_PATH','DB_HOST','DB_PORT','DB_NAME','DB_USER','DB_PASS']as$key){unset($environment[$key]);}
    if($explicit!==null){$environment['APP_CONFIG_FILE']=$explicit;}
    $code='try { require '.var_export($deployment.'/cafe_app/includes/config.php',true).'; echo json_encode(app_config(), JSON_THROW_ON_ERROR); } catch (Throwable $error) { fwrite(STDERR,get_class($error)); exit(1); }';
    return shared_package_php($code,$environment);
}
function shared_package_remove(string $directory):void{
    if(!is_dir($directory)){return;}
    foreach(new FilesystemIterator($directory,FilesystemIterator::SKIP_DOTS)as$file){
        if($file->isDir()&&!$file->isLink()){shared_package_remove($file->getPathname());}else{unlink($file->getPathname());}
    }
    rmdir($directory);
}
try{
    if(!class_exists(ZipArchive::class)){throw new RuntimeException('Shared package checks require PHP zip extension');}
    foreach(array_unique(array_merge(array_values($files),['scripts/package.php']))as$path){
        $parent=dirname($source.'/'.$path);
        if(!is_dir($parent)&&!mkdir($parent,0700,true)){throw new RuntimeException('Cannot create isolated package source');}
        if(!copy($actual.'/'.$path,$source.'/'.$path)){throw new RuntimeException('Cannot copy package source fixture');}
    }
    $sentinel='SHARED_PACKAGE_PRIVATE_FIXTURE_'.bin2hex(random_bytes(6));
    foreach(['config/local.php','.env','includes/seed.php','scripts/seed.php','tests/private.php','public/router.php','Dockerfile','public/index.html','public/.apex-secret']as$excluded){
        $parent=dirname($source.'/'.$excluded);if(!is_dir($parent)){mkdir($parent,0700,true);}
        file_put_contents($source.'/'.$excluded,$sentinel);
    }
    foreach([
        ['--shared-subdomain'],
        ['--shared-subdomain','--shared-subdomain','--output='.$temporary.'/duplicate-flag.zip'],
        ['--output='.$temporary.'/duplicate-output.zip','--output='.$temporary.'/duplicate-output2.zip','--shared-subdomain'],
        ['--shared-subdomain','--unknown','--output='.$temporary.'/unknown-flag.zip'],
    ]as$arguments){
        [$status]=shared_package_command($arguments);
        shared_package_check($status===2&&glob($temporary.'/*.zip')===[],'Missing/duplicate/unknown flags cannot create a shared release');
    }
    $outerPublic=$temporary.'/public_html';mkdir($outerPublic);
    [$status]=shared_package_command(['--shared-subdomain','--output='.$outerPublic.'/release.zip']);
    shared_package_check($status!==0&&!file_exists($outerPublic.'/release.zip'),'Shared release output rejected under parent public_html');
    $privateOutput=$temporary.'/private-output';mkdir($privateOutput);
    if(@symlink($privateOutput,$outerPublic.'/private-output-alias')){
        [$status]=shared_package_command(['--shared-subdomain','--output='.$outerPublic.'/private-output-alias/release.zip']);
        shared_package_check($status!==0&&!file_exists($privateOutput.'/release.zip'),'Parent public_html output alias cannot publish into private canonical parent');
    }else{fwrite(STDOUT,"Shared output symlink probe skipped: platform does not permit symlink creation.\n");}
    $output=$temporary.'/shared.zip';
    [$status,$message]=shared_package_command(['--shared-subdomain','--output='.$output]);
    shared_package_check($status===0&&is_file($output),'Shared release created: '.$message);
    $originalHash=hash_file('sha256',$output);
    [$status]=shared_package_command(['--output='.$output,'--shared-subdomain']);
    shared_package_check($status!==0&&hash_file('sha256',$output)===$originalHash,'Shared release never overwrites existing output');
    $zip=new ZipArchive();shared_package_check($zip->open($output)===true,'Shared ZIP opens');
    $entries=[];
    for($index=0;$index<$zip->numFiles;$index++){
        $entry=$zip->getNameIndex($index);$entries[]=$entry;
        shared_package_check(is_string($entry)&&!str_starts_with($entry,'/')&&!in_array('..',explode('/',$entry),true),'Shared ZIP paths are relative without traversal');
        $contents=$zip->getFromIndex($index);
        shared_package_check(is_string($contents)&&!str_contains($contents,$sentinel),'Shared ZIP excludes private credential and development fixtures');
    }
    $expected=array_merge(array_keys($files),['release.json']);sort($entries);sort($expected);
    shared_package_check(count($entries)===24&&$entries===$expected,'Exact shared 24-entry archive protects apex paths');
    $manifest=json_decode($zip->getFromName('release.json'),true,512,JSON_THROW_ON_ERROR);
    shared_package_check($manifest['format']===1&&$manifest['domain']==='cafes.myfanverse.in'&&$manifest['php_minimum']==='8.2'&&$manifest['database']==='MariaDB 10.11+','Shared target and runtime metadata');
    shared_package_check($manifest['layout']==='shared-subdomain'&&$manifest['document_root']==='public_html/cafes'&&$manifest['private_root']==='cafe_app','Shared public/private layout metadata');
    $hashPaths=array_keys($manifest['files_sha256']);sort($hashPaths);$payloadPaths=array_keys($files);sort($payloadPaths);
    shared_package_check(count($hashPaths)===23&&$hashPaths===$payloadPaths,'Manifest hashes cover all 23 payload files');
    foreach($files as$destination=>$input){
        $data=$zip->getFromName($destination);
        shared_package_check($data===file_get_contents($source.'/'.$input),'Shared source bytes preserved: '.$destination);
        shared_package_check($manifest['files_sha256'][$destination]===hash('sha256',$data),'Independent shared hash: '.$destination);
    }
    $second=$temporary.'/shared-reversed.zip';
    [$status,$message]=shared_package_command(['--output='.$second,'--shared-subdomain']);
    shared_package_check($status===0,'Shared flag accepted after output: '.$message);
    $reverse=new ZipArchive();shared_package_check($reverse->open($second)===true,'Reversed flag ZIP opens');
    $reverseManifest=json_decode($reverse->getFromName('release.json'),true,512,JSON_THROW_ON_ERROR);
    shared_package_check($reverse->numFiles===24&&$reverseManifest['layout']==='shared-subdomain'&&$reverseManifest['files_sha256']===$manifest['files_sha256'],'Argument order preserves shared payload');$reverse->close();

    $deployment=$temporary.'/deployment';mkdir($deployment.'/public_html',0700,true);
    $apex='EXISTING_APEX_HTML_FIXTURE';$apexRules='EXISTING_APEX_RULES_FIXTURE';
    file_put_contents($deployment.'/public_html/index.html',$apex);
    file_put_contents($deployment.'/public_html/.htaccess',$apexRules);
    shared_package_check($zip->extractTo($deployment),'Shared ZIP safely extracts');$zip->close();
    shared_package_check(file_get_contents($deployment.'/public_html/index.html')===$apex&&file_get_contents($deployment.'/public_html/.htaccess')===$apexRules,'Extracting shared release preserves existing apex HTML and rules');
    $operator=['APP_ENV'=>'production','DEMO_MODE'=>'false','APP_BASE_PATH'=>'','DB_HOST'=>'localhost','DB_PORT'=>'3306','DB_NAME'=>'shared_fixture','DB_USER'=>'shared_fixture_user','DB_PASS'=>'SHARED_OPERATOR_TEST_ONLY'];
    file_put_contents($deployment.'/cafe_app/config/local.php',"<?php return ".var_export($operator,true).";\n");
    [$status,$result,$error]=shared_package_config($deployment);
    shared_package_check($status===0,'Private cafe_app config autodiscovery: '.$error);
    $loaded=json_decode($result,true,512,JSON_THROW_ON_ERROR);
    shared_package_check($loaded['app_env']==='production'&&$loaded['demo_mode']===false&&$loaded['base_path']===''&&$loaded['db_user']==='shared_fixture_user'&&$loaded['db_pass']==='SHARED_OPERATOR_TEST_ONLY','Shared operator values load outside both public sites');
    $publicConfig=$deployment.'/public_html/cafes/config.txt';
    file_put_contents($publicConfig,"<?php return ".var_export($operator,true).";\n");
    [$status]=shared_package_config($deployment,$publicConfig);
    shared_package_check($status===1,'Shared loader rejects config in actual shared public tree');
    $alias=$deployment.'/public_html/cafes/config-alias.txt';
    if(@symlink($deployment.'/cafe_app/config/local.php',$alias)){
        [$status]=shared_package_config($deployment,$alias);
        shared_package_check($status===1,'Public alias to cafe_app private config rejected');
    }else{fwrite(STDOUT,"Shared config symlink probe skipped: platform does not permit symlink creation.\n");}

    // Exercise wrapper failure independently, without a database or actual hosting.
    $probe=$temporary.'/bootstrap-fixture';mkdir($probe.'/public_html/cafes',0700,true);
    copy($source.'/deploy/shared/index.php',$probe.'/public_html/cafes/index.php');
    $probeCode='require '.var_export($probe.'/public_html/cafes/index.php',true).'; fwrite(STDERR,"STATUS=".http_response_code()." BUFFER=".ob_get_level());';
    for($case=0;$case<2;$case++){
        if($case===1){
            mkdir($probe.'/cafe_app/public_html',0700,true);
            file_put_contents($probe.'/cafe_app/public_html/index.php',"<?php echo ".var_export($sentinel,true)."; ob_start(); echo ".var_export($sentinel.'nested',true)."; throw new RuntimeException('fixture failure at '.__FILE__);");
        }
        [$status,$body,$error]=shared_package_php($probeCode);
        shared_package_check($status===0&&str_contains($error,'STATUS=503'),'Missing or failing private entry produces controlled wrapper503');
        shared_package_check(str_contains($body,'Temporarily unavailable')&&!str_contains($body,$probe)&&!str_contains($body,$sentinel)&&!preg_match('/Warning:|Fatal error:|Stack trace|RuntimeException/i',$body),'Wrapper failure discards partial output and private details');
        shared_package_check(str_contains($error,'BUFFER=0'),'Wrapper failure balances nested output buffers');
    }
    unlink($source.'/deploy/shared/index.php');
    [$status]=shared_package_command(['--shared-subdomain','--output='.$temporary.'/missing-wrapper.zip']);
    shared_package_check($status!==0&&!file_exists($temporary.'/missing-wrapper.zip'),'Missing shared wrapper cannot publish partial release');
    fwrite(STDOUT,"Shared package checks passed: {$checks}.\n");
}catch(Throwable $error){
    fwrite(STDERR,'FAIL after '.$checks.': '.$error->getMessage()."\n");$exitCode=1;
}finally{shared_package_remove($temporary);}
exit($exitCode);
