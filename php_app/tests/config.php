<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }

// Use an isolated application tree: never read or rewrite a contributor's local.php.
$source=dirname(__DIR__).'/includes/config.php';
$temporary=sys_get_temp_dir().'/cafe-config-check-'.bin2hex(random_bytes(8));
$checks=0;
$exitCode=0;
$keys=['APP_CONFIG_FILE','APP_ENV','DEMO_MODE','APP_BASE_PATH','DB_HOST','DB_PORT','DB_NAME','DB_USER','DB_PASS'];
function config_check(bool $condition,string $label):void{
    global $checks;
    if(!$condition){throw new RuntimeException($label);}
    $checks++;
}
function config_result(array $values=[]):array{
    global $temporary,$keys;
    $environment=getenv();
    foreach($keys as$key){unset($environment[$key]);}
    // PHP proc_open omits empty values from its environment array. Set requested
    // values inside the child too, so an intentional empty environment is tested.
    $code='foreach ('.var_export($values,true).' as $key => $value) { putenv($key."=".$value); } try { require '.var_export($temporary.'/includes/config.php',true).'; echo json_encode(app_config(), JSON_THROW_ON_ERROR); } catch (Throwable $error) { fwrite(STDERR, get_class($error).": ".$error->getMessage()); exit(1); }';
    $process=proc_open([PHP_BINARY,'-d','display_errors=1','-r',$code],[1=>['pipe','w'],2=>['pipe','w']],$pipes,$temporary,array_merge($environment,$values));
    if(!is_resource($process)){throw new RuntimeException('Cannot run configuration subprocess');}
    $stdout=stream_get_contents($pipes[1]);$stderr=stream_get_contents($pipes[2]);
    fclose($pipes[1]);fclose($pipes[2]);$status=proc_close($process);
    return[$status,$stdout,$stderr];
}
function config_file(string $path,mixed $value):void{
    if(file_put_contents($path,"<?php\nreturn ".var_export($value,true).";\n")===false){throw new RuntimeException('Cannot write configuration fixture');}
}
function config_remove(string $directory):void{
    if(!is_dir($directory)){return;}
    foreach(new FilesystemIterator($directory,FilesystemIterator::SKIP_DOTS)as$file){
        if($file->isDir()&&!$file->isLink()){config_remove($file->getPathname());}
        else{unlink($file->getPathname());}
    }
    rmdir($directory);
}

try{
    foreach(['includes','config','public','public_html']as$directory){
        if(!mkdir($temporary.'/'.$directory,0700,true)){throw new RuntimeException('Cannot create isolated config tree');}
    }
    if(!copy($source,$temporary.'/includes/config.php')){throw new RuntimeException('Cannot copy actual config loader');}
    [$status,$output,$error]=config_result(['DB_USER'=>'environment_user']);
    config_check($status===0,'Missing optional local file with configured environment: '.$error);
    $defaults=json_decode($output,true,512,JSON_THROW_ON_ERROR);
    config_check($defaults['app_env']==='production'&&$defaults['demo_mode']===false,'Safe production defaults');
    config_check($defaults['base_path']===''&&$defaults['db_host']==='127.0.0.1'&&$defaults['db_port']===3306,'Runtime defaults');
    config_check($defaults['db_user']==='environment_user'&&$defaults['db_pass']==='','Environment-only credentials');

    $fileValues=['APP_ENV'=>'development','DEMO_MODE'=>'true','APP_BASE_PATH'=>'/file-guide','DB_HOST'=>'file-host','DB_PORT'=>'3307','DB_NAME'=>'file_database','DB_USER'=>'file_user','DB_PASS'=>'fixture-password-only'];
    $private=$temporary.'/private.php';config_file($private,$fileValues);
    [$status,$output,$error]=config_result(['APP_CONFIG_FILE'=>$private]);
    config_check($status===0,'Explicit absolute private file loads: '.$error);
    $loaded=json_decode($output,true,512,JSON_THROW_ON_ERROR);
    config_check($loaded===['app_env'=>'development','demo_mode'=>true,'base_path'=>'/file-guide','db_host'=>'file-host','db_port'=>3307,'db_name'=>'file_database','db_user'=>'file_user','db_pass'=>'fixture-password-only'],'Every allowed file value maps to config');

    [$status,$output,$error]=config_result(['APP_CONFIG_FILE'=>$private,'APP_ENV'=>'test','DEMO_MODE'=>'false','APP_BASE_PATH'=>'','DB_HOST'=>'localhost','DB_PORT'=>'3306','DB_NAME'=>'environment_test','DB_USER'=>'environment_user','DB_PASS'=>'']);
    config_check($status===0,'Environment override result: '.$error);
    $overridden=json_decode($output,true,512,JSON_THROW_ON_ERROR);
    config_check($overridden===['app_env'=>'test','demo_mode'=>false,'base_path'=>'','db_host'=>'localhost','db_port'=>3306,'db_name'=>'environment_test','db_user'=>'environment_user','db_pass'=>''],'Environment overrides every file key, including intentionally empty values');
    foreach(['APP_ENV','DEMO_MODE','DB_USER','DB_NAME','DB_PORT','DB_HOST']as$key){
        [$status]=config_result(['APP_CONFIG_FILE'=>$private,$key=>'']);
        config_check($status===1,'Explicit empty '.$key.' does not fall back to file');
    }

    config_file($temporary.'/config/local.php',$fileValues);
    [$status,$output,$error]=config_result();
    config_check($status===0&&json_decode($output,true,512,JSON_THROW_ON_ERROR)===$loaded,'Private local.php autodiscovery: '.$error);
    config_file($temporary.'/config/local.php',['DB_USER'=>'local_user']);
    [$status,$output,$error]=config_result(['APP_CONFIG_FILE'=>$private]);
    config_check($status===0&&json_decode($output,true,512,JSON_THROW_ON_ERROR)===$loaded,'Explicit file takes precedence over autodiscovery: '.$error);
    unlink($temporary.'/config/local.php');

    foreach([$temporary.'/missing.php','relative.php']as$path){
        [$status]=config_result(['APP_CONFIG_FILE'=>$path,'DB_USER'=>'environment_user']);
        config_check($status===1,'Missing or relative explicit configuration rejected');
    }
    $public=$temporary.'/public/leaked.php';config_file($public,$fileValues);
    $publicHtml=$temporary.'/public_html/leaked.php';config_file($publicHtml,$fileValues);
    foreach([$public,$publicHtml,$temporary.'/public/../public/leaked.php',$temporary.'/public_html/../public_html/leaked.php']as$path){
        [$status]=config_result(['APP_CONFIG_FILE'=>$path]);
        config_check($status===1,'Canonical public configuration rejected');
    }
    foreach(['public','public_html']as$directory){
        $alias=$temporary.'/'.$directory.'/private-alias.php';
        if(@symlink($private,$alias)){
            [$status]=config_result(['APP_CONFIG_FILE'=>$alias]);
            config_check($status===1,'Public alias to a valid private file rejected');
        }else{fwrite(STDOUT,"Public config symlink probe skipped: platform does not permit symlink creation.\n");}
    }
    $directoryAlias=$temporary.'/public-portal';
    if(is_link($temporary.'/public/private-alias.php')&&@symlink($temporary.'/public',$directoryAlias)){
        [$status]=config_result(['APP_CONFIG_FILE'=>$directoryAlias.'/private-alias.php']);
        config_check($status===1,'Path alias through public ancestor to private target rejected');
    }else{fwrite(STDOUT,"Public ancestor symlink probe skipped: platform does not permit symlink creation.\n");}
    if(DIRECTORY_SEPARATOR==='/'){
        // These are real, valid relative filenames on Linux. A Windows-looking
        // prefix must not make them acceptable absolute operator paths.
        foreach(['C:\\cafe-config-check.php','\\\\server\\share\\cafe-config-check.php']as$alien){
            config_file($temporary.'/'.$alien,$fileValues);
            [$status]=config_result(['APP_CONFIG_FILE'=>$alien]);
            config_check($status===1,'Windows drive/UNC path rejected on Linux despite existing relative file');
        }
    }elseif(preg_match('/^[A-Za-z]:/',$private)===1){
        $rooted=preg_replace('/^[A-Za-z]:/','',str_replace('\\','/',$private));
        [$status]=config_result(['APP_CONFIG_FILE'=>$rooted]);
        config_check($status===1,'Drive-relative Unix-looking rooted path rejected on Windows');
    }else{fwrite(STDOUT,"Windows rooted-path probe skipped: temporary fixture uses a UNC root.\n");}

    foreach([null,'not-an-array',42,['UNKNOWN'=>'value'],['APP_CONFIG_FILE'=>$private],['DB_USER'=>42],['DB_PASS'=>[]],[0=>'value']]as$invalid){
        config_file($private,$invalid);
        [$status]=config_result(['APP_CONFIG_FILE'=>$private,'DB_USER'=>'environment_user']);
        config_check($status===1,'Malformed file return type, key or value rejected');
    }
    foreach([
        ['APP_ENV'=>'invalid'],['DEMO_MODE'=>'yes'],['DB_PORT'=>'0'],['DB_PORT'=>'65536'],
        ['DB_HOST'=>'localhost;dsn'],['DB_NAME'=>'bad-name'],['APP_BASE_PATH'=>'/a/../private'],
        ['APP_ENV'=>'production','DEMO_MODE'=>'true'],
    ]as$invalid){
        config_file($private,array_replace($fileValues,$invalid));
        [$status]=config_result(['APP_CONFIG_FILE'=>$private]);
        config_check($status===1,'Existing strict validation also applies to file values');
    }
    file_put_contents($private,"<?php return [;\n");
    [$status]=config_result(['APP_CONFIG_FILE'=>$private]);
    config_check($status===1,'Configuration parse error is catchable');
    config_file($temporary.'/config/local.php',['DB_USER'=>['invalid']]);
    [$status]=config_result(['DB_USER'=>'environment_user']);
    config_check($status===1,'Malformed autodiscovered file rejected even with environment overrides');
    unlink($temporary.'/config/local.php');
    file_put_contents($temporary.'/.env',"DB_USER=dotenv_user\nDB_PASS=dotenv_password\n");
    [$status]=config_result();
    config_check($status===1,'A .env file does not populate missing credentials');
    [$status,$output,$error]=config_result(['DB_USER'=>'environment_user']);
    config_check($status===0&&json_decode($output,true,512,JSON_THROW_ON_ERROR)['db_pass']==='','A .env file is not auto-loaded: '.$error);
    fwrite(STDOUT,"Configuration checks passed: {$checks}.\n");
}catch(Throwable $error){
    fwrite(STDERR,'FAIL after '.$checks.': '.$error->getMessage()."\n");$exitCode=1;
}finally{config_remove($temporary);}
exit($exitCode);
