<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }

$actual=dirname(__DIR__);
$temporary=sys_get_temp_dir().'/cafe-package-check-'.bin2hex(random_bytes(8));
$source=$temporary.'/source';
$checks=0;$exitCode=0;
$files=[
    'public/index.php'=>'public_html/index.php',
    'public/.htaccess'=>'public_html/.htaccess',
    'public/static/site.css'=>'public_html/static/site.css',
    'config/local.example.php'=>'config/local.example.php',
    'schema/schema.sql'=>'schema/schema.sql',
    'schema/README.md'=>'schema/README.md',
    'scripts/schema.php'=>'scripts/schema.php',
    'scripts/schema_helpers.php'=>'scripts/schema_helpers.php',
    'includes/config.php'=>'includes/config.php',
    'includes/db.php'=>'includes/db.php',
    'includes/request.php'=>'includes/request.php',
    'includes/catalogue.php'=>'includes/catalogue.php',
    'includes/web.php'=>'includes/web.php',
    'templates/header.php'=>'templates/header.php',
    'templates/footer.php'=>'templates/footer.php',
    'templates/catalogue.php'=>'templates/catalogue.php',
    'templates/cafe_detail.php'=>'templates/cafe_detail.php',
    'templates/about.php'=>'templates/about.php',
    'templates/error.php'=>'templates/error.php',
    'templates/_evidence.php'=>'templates/_evidence.php',
];
function package_check(bool $condition,string $label):void{
    global $checks;if(!$condition){throw new RuntimeException($label);}$checks++;
}
function package_command(array $arguments):array{
    global $source;
    $process=proc_open(array_merge([PHP_BINARY,$source.'/scripts/package.php'],$arguments),[1=>['pipe','w'],2=>['pipe','w']],$pipes,$source);
    if(!is_resource($process)){throw new RuntimeException('Cannot run package command');}
    $output=stream_get_contents($pipes[1]).stream_get_contents($pipes[2]);
    fclose($pipes[1]);fclose($pipes[2]);return[proc_close($process),$output];
}
function package_remove(string $directory):void{
    if(!is_dir($directory)){return;}
    foreach(new FilesystemIterator($directory,FilesystemIterator::SKIP_DOTS)as$file){
        if($file->isDir()&&!$file->isLink()){package_remove($file->getPathname());}
        else{unlink($file->getPathname());}
    }
    rmdir($directory);
}

try{
    if(!class_exists(ZipArchive::class)){throw new RuntimeException('Package tests require PHP zip extension');}
    // Copy only known source files, never an operator's private config or credentials.
    foreach(array_merge(array_keys($files),['scripts/package.php'])as$path){
        $parent=dirname($source.'/'.$path);
        if(!is_dir($parent)&&!mkdir($parent,0700,true)){throw new RuntimeException('Cannot make isolated source directory');}
        if(!copy($actual.'/'.$path,$source.'/'.$path)){throw new RuntimeException('Cannot copy release source fixture');}
    }
    mkdir($source.'/public_html');
    $sentinel='PACKAGE_TEST_SECRET_DO_NOT_BUNDLE_'.bin2hex(random_bytes(4));
    foreach(['config/local.php','.env','includes/seed.php','scripts/seed.php','tests/private.php','public/router.php','Dockerfile','public/unexpected.txt']as$excluded){
        $parent=dirname($source.'/'.$excluded);
        if(!is_dir($parent)){mkdir($parent,0700,true);}
        file_put_contents($source.'/'.$excluded,$sentinel);
    }
    [$status]=package_command([]);package_check($status===2,'Package command requires explicit output');
    foreach(['release-relative.zip',$source.'/public/release.zip',$source.'/public_html/release.zip',$source.'/public/../public/release.zip',$temporary.'/not-a-zip.txt']as$invalid){
        [$status]=package_command(['--output='.$invalid]);
        $candidate=str_starts_with($invalid,'release-')?$source.'/'.$invalid:$invalid;
        package_check($status!==0&&!file_exists($candidate),'Unsafe or invalid output refused without creating a file');
    }
    if(DIRECTORY_SEPARATOR==='/'){
        foreach(['C:\\release.zip','\\\\server\\share\\release.zip']as$alien){
            [$status]=package_command(['--output='.$alien]);
            package_check($status!==0&&!file_exists($source.'/'.$alien),'Windows drive/UNC output rejected on Linux without writing relative ZIP');
        }
    }elseif(preg_match('/^[A-Za-z]:/',$temporary)===1){
        $rooted=preg_replace('/^[A-Za-z]:/','',str_replace('\\','/',$temporary.'/rooted-release.zip'));
        [$status]=package_command(['--output='.$rooted]);
        package_check($status!==0&&!file_exists($temporary.'/rooted-release.zip'),'Drive-relative Unix-looking output rejected on Windows');
    }else{fwrite(STDOUT,"Windows rooted-output probe skipped: temporary fixture uses a UNC root.\n");}
    $privateOutput=$temporary.'/private-output';mkdir($privateOutput);
    foreach(['public','public_html']as$directory){
        $alias=$source.'/'.$directory.'/output-portal';
        $candidate=$directory.'-release.zip';
        if(@symlink($privateOutput,$alias)){
            [$status]=package_command(['--output='.$alias.'/'.$candidate]);
            package_check($status!==0&&!file_exists($privateOutput.'/'.$candidate),'Output beneath public directory alias refused despite private canonical parent');
        }else{fwrite(STDOUT,"Output directory symlink probe skipped: platform does not permit symlink creation.\n");}
    }
    $output=$temporary.'/release.zip';
    [$status,$message]=package_command(['--output='.$output]);
    package_check($status===0&&is_file($output),'Release ZIP built: '.$message);
    $originalHash=hash_file('sha256',$output);
    [$status]=package_command(['--output='.$output]);
    package_check($status!==0&&hash_file('sha256',$output)===$originalHash,'Existing output never overwritten');
    $zip=new ZipArchive();package_check($zip->open($output)===true,'Generated archive opens');
    $entries=[];
    for($index=0;$index<$zip->numFiles;$index++){
        $entry=$zip->getNameIndex($index);$entries[]=$entry;
        package_check(is_string($entry)&&!str_starts_with($entry,'/')&&!in_array('..',explode('/',$entry),true),'Archive paths are relative without traversal');
        $contents=$zip->getFromIndex($index);
        package_check(is_string($contents)&&!str_contains($contents,$sentinel),'Excluded fixture credentials never appear in archive contents');
    }
    $expected=array_merge(array_values($files),['release.json']);sort($entries);sort($expected);
    package_check($entries===$expected,'Exact deployable allowlist: public_html, private runtime, safe example, schema and schema CLI');
    $manifest=json_decode($zip->getFromName('release.json'),true,512,JSON_THROW_ON_ERROR);
    package_check($manifest['format']===1&&$manifest['domain']==='myfanverse.in'&&$manifest['php_minimum']==='8.2'&&$manifest['database']==='MariaDB 10.11+','Release manifest target and supported runtime');
    package_check(preg_match('/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\+00:00$/D',$manifest['built_at_utc'])===1,'Manifest timestamp is explicitly UTC');
    $manifestPaths=array_keys($manifest['files_sha256']);sort($manifestPaths);$expectedPaths=array_values($files);sort($expectedPaths);
    package_check($manifestPaths===$expectedPaths,'Manifest hashes cover every runtime file exactly');
    foreach($files as$input=>$entry){
        $contents=$zip->getFromName($entry);
        package_check($contents===file_get_contents($source.'/'.$input),'Runtime source preserved in '.$entry);
        package_check($manifest['files_sha256'][$entry]===hash('sha256',$contents),'Correct independent hash for '.$entry);
    }
    $deployment=$temporary.'/deployment';mkdir($deployment);
    package_check($zip->extractTo($deployment),'Safe allowlisted archive extracts');$zip->close();
    $local=['APP_ENV'=>'production','DEMO_MODE'=>'false','APP_BASE_PATH'=>'','DB_HOST'=>'localhost','DB_PORT'=>'3306','DB_NAME'=>'packaged_fixture','DB_USER'=>'packaged_fixture_user','DB_PASS'=>'PACKAGED_RUNTIME_TEST_SECRET'];
    file_put_contents($deployment.'/config/local.php',"<?php return ".var_export($local,true).";\n");
    $environment=getenv();foreach(['APP_CONFIG_FILE','APP_ENV','DEMO_MODE','APP_BASE_PATH','DB_HOST','DB_PORT','DB_NAME','DB_USER','DB_PASS']as$key){unset($environment[$key]);}
    $code='require '.var_export($deployment.'/includes/config.php',true).'; echo json_encode(app_config(), JSON_THROW_ON_ERROR);';
    $process=proc_open([PHP_BINARY,'-r',$code],[1=>['pipe','w'],2=>['pipe','w']],$pipes,$deployment,$environment);
    if(!is_resource($process)){throw new RuntimeException('Cannot check packaged configuration fallback');}
    $result=stream_get_contents($pipes[1]);$error=stream_get_contents($pipes[2]);fclose($pipes[1]);fclose($pipes[2]);$status=proc_close($process);
    package_check($status===0,'Packaged private config autodiscovery works: '.$error);
    $loaded=json_decode($result,true,512,JSON_THROW_ON_ERROR);
    package_check($loaded['app_env']==='production'&&$loaded['demo_mode']===false&&$loaded['db_user']==='packaged_fixture_user'&&$loaded['db_pass']==='PACKAGED_RUNTIME_TEST_SECRET','Packaged operator values load outside public_html');
    $missing=$source.'/schema/schema.sql';$schema=file_get_contents($missing);unlink($missing);
    [$status]=package_command(['--output='.$temporary.'/missing-source.zip']);
    package_check($status!==0&&!file_exists($temporary.'/missing-source.zip'),'Missing runtime file fails without publishing partial archive');
    file_put_contents($missing,$schema);
    // On supported platforms, a linked required file must not bypass the source allowlist.
    $linked=$source.'/templates/footer.php';unlink($linked);
    if(@symlink($source.'/config/local.php',$linked)){
        [$status]=package_command(['--output='.$temporary.'/linked-source.zip']);
        package_check($status!==0&&!file_exists($temporary.'/linked-source.zip'),'Symlinked runtime file refused without publishing private contents');
    }else{fwrite(STDOUT,"Symlink probe skipped: platform does not permit symlink creation.\n");}
    if(is_link($linked)){unlink($linked);}
    if(!copy($actual.'/templates/footer.php',$linked)){throw new RuntimeException('Cannot restore ordinary runtime fixture');}
    $outsideTemplates=$temporary.'/outside-templates';
    if(!rename($source.'/templates',$outsideTemplates)){throw new RuntimeException('Cannot prepare linked directory fixture');}
    file_put_contents($outsideTemplates.'/footer.php',$sentinel);
    if(@symlink($outsideTemplates,$source.'/templates')){
        [$status]=package_command(['--output='.$temporary.'/linked-directory.zip']);
        package_check($status!==0&&!file_exists($temporary.'/linked-directory.zip'),'Symlinked runtime ancestor cannot publish files outside the source tree');
    }else{fwrite(STDOUT,"Directory symlink probe skipped: platform does not permit symlink creation.\n");}
    fwrite(STDOUT,"Package checks passed: {$checks}.\n");
}catch(Throwable $error){
    fwrite(STDERR,'FAIL after '.$checks.': '.$error->getMessage()."\n");$exitCode=1;
}finally{package_remove($temporary);}
exit($exitCode);
