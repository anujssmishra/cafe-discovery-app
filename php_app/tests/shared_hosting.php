<?php
declare(strict_types=1);

// Read-only local fixture checks; never contact the real domain.
if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
if($argc!==2||!in_array($argv[1],['http://shared-hosting','http://127.0.0.1:8082'],true)){
    fwrite(STDERR,"Usage: php php_app/tests/shared_hosting.php http://shared-hosting (local fixture only)\n");exit(2);
}
$base=$argv[1];$checks=0;
function shared_hosting_check(bool $condition,string $label):void{
    global $checks;if(!$condition){throw new RuntimeException($label);}$checks++;
}
function shared_hosting_response(string $path,string $host='cafes.myfanverse.in',string $method='GET'):array{
    global $base;
    $body=file_get_contents($base.$path,false,stream_context_create(['http'=>[
        'method'=>$method,'header'=>'Host: '.$host."\r\n",'ignore_errors'=>true,'follow_location'=>0,'timeout'=>10,
    ]]));
    if($body===false){throw new RuntimeException('No local shared-hosting response');}
    preg_match('/^HTTP\/\S+\s+(\d+)/',$http_response_header[0]??'',$match);
    return[(int)($match[1]??0),$body,implode("\n",$http_response_header)];
}
function shared_hosting_safe(string $body):bool{
    return !preg_match('/Warning:|Fatal error:|Notice:|PDOException|SQLSTATE|Stack trace|local-demo-only/i',$body);
}
try{
    [$status,$body]=shared_hosting_response('/');
    shared_hosting_check($status===200&&str_contains($body,'Browse cafés'),'Shared subdomain catalogue via private production config');
    shared_hosting_check(!str_contains($body,'Demo mode:')&&!str_contains($body,'Paper Lantern')&&shared_hosting_safe($body),'Production hides demo records and private details');
    [$status,$body]=shared_hosting_response('/?q=QA%20Match&area=qa-active&page=2');
    shared_hosting_check($status===200&&str_contains($body,'QA Match 12')&&!str_contains($body,'QA Match 00'),'Shared combined filters and page two');
    shared_hosting_check(str_contains($body,'q=QA%20Match&amp;area=qa-active&amp;page=3'),'Shared pagination preserves filters');
    [$status,$body]=shared_hosting_response('/cafes/90000000-0000-4000-8000-000000000000/');
    shared_hosting_check($status===200&&str_contains($body,'QA Match 00'),'Shared full UUID detail route');
    shared_hosting_check(str_contains($body,'href="/static/site.css"')&&str_contains($body,'href="/about/"'),'Subdomain links remain relative to its document root');
    [$status,$body]=shared_hosting_response('/about/');
    shared_hosting_check($status===200&&str_contains($body,'About'),'Shared about route');
    [$status,$body]=shared_hosting_response('/?q=does-not-exist');
    shared_hosting_check($status===200&&str_contains($body,'No cafés found'),'Shared empty result state');
    foreach(['/?q%5B%5D=bad','/?area%5B%5D=bad','/?page%5B%5D=bad']as$path){
        [$status,$body]=shared_hosting_response($path);
        shared_hosting_check($status===400&&shared_hosting_safe($body),'Shared malformed query safely rejected');
    }
    foreach([
        '/cafes/not-a-uuid/',
        '/cafes/90000000-0000-4000-8000-999999999999/',
        '/cafes/90000000-0000-4000-8000-000000000100/',
        '/cafes/90000000-0000-4000-8000-000000000101/',
        '/cafes/b1833e2a-f772-50cc-8dfc-b08eb028fe04/',
    ]as$path){
        [$status,$body]=shared_hosting_response($path);
        shared_hosting_check($status===404&&shared_hosting_safe($body),'Missing/inactive/hidden/demo shared detail returns404');
    }
    foreach([
        '/cafe_app/config/local.php','/cafe_app/includes/config.php','/cafe_app/schema/schema.sql',
        '/cafe_app/scripts/schema.php','/cafe_app/public_html/index.php','/config/local.php',
        '/config/local.example.php','/release.json','/.env','/.htaccess',
    ]as$path){
        [$status,$body]=shared_hosting_response($path);
        shared_hosting_check(in_array($status,[403,404],true)&&shared_hosting_safe($body),'Private shared release path unavailable: '.$path);
    }
    [$status,$body,$headers]=shared_hosting_response('/static/site.css');
    shared_hosting_check($status===200&&str_contains(strtolower($headers),'content-type: text/css')&&str_contains($body,'@media'),'Subdomain stylesheet served correctly');
    [$status,$body]=shared_hosting_response('/cafes/90000000-0000-4000-8000-000000000000/','cafes.myfanverse.in','HEAD');
    shared_hosting_check($status===200&&$body==='','Shared HEAD response');
    [$status]=shared_hosting_response('/','cafes.myfanverse.in','POST');
    shared_hosting_check($status===405,'Shared unsupported mutation method rejected');
    [$status,$body]=shared_hosting_response('/','CAFES.MYFANVERSE.IN');
    shared_hosting_check($status===200&&str_contains($body,'Browse cafés'),'Subdomain host guard is case-insensitive');
    [$status,$body,$headers]=shared_hosting_response('/static/site.css','cafes.myfanverse.in:8082');
    shared_hosting_check($status===200&&str_contains(strtolower($headers),'content-type: text/css'),'Subdomain host guard accepts optional port before static serving');

    [$status,$apex]=shared_hosting_response('/','myfanverse.in');
    shared_hosting_check($status===200&&str_contains($apex,'Existing custom site fixture')&&!str_contains($apex,'Browse cafés'),'Apex serves its existing site');
    foreach(['/cafes/','/cafes/index.php','/cafes/static/site.css','/cafes/about/']as$path){
        [$status,$body]=shared_hosting_response($path,'myfanverse.in');
        shared_hosting_check($status===403&&!str_contains($body,'Browse cafés')&&!str_contains($body,'@media')&&shared_hosting_safe($body),'Apex access to shared dynamic/static folder denied: '.$path);
    }
    foreach(['/cafe_app/config/local.php','/cafe_app/includes/config.php','/cafe_app/schema/schema.sql','/release.json']as$path){
        [$status,$body]=shared_hosting_response($path,'myfanverse.in');
        shared_hosting_check(in_array($status,[403,404],true)&&shared_hosting_safe($body),'Private application is also unavailable through apex: '.$path);
    }
    foreach(['/cafes/','/cafes/static/site.css']as$path){
        [$status,$body]=shared_hosting_response($path,'cafes.myfanverse.in.evil.invalid');
        shared_hosting_check($status===403&&!str_contains($body,'Browse cafés')&&!str_contains($body,'@media'),'Lookalike host cannot bypass shared folder guard');
    }
    [$status,$after]=shared_hosting_response('/','myfanverse.in');
    shared_hosting_check($status===200&&$after===$apex,'Apex placeholder remains unchanged after shared route checks');
    fwrite(STDOUT,"Local shared-subdomain Apache checks passed: {$checks}.\n");
}catch(Throwable $error){
    fwrite(STDERR,'FAIL after '.$checks.': '.$error->getMessage()."\n");exit(1);
}
