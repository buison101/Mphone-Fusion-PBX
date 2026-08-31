<?php
	require_once dirname(__DIR__,3).'/resources/require.php';
	require_once dirname(__DIR__).'/resources/identity_session.php';
	require_once dirname(__DIR__).'/resources/call_routing_platform.php';
	header('Content-Type: application/json; charset=utf-8'); header('Cache-Control: no-store');
	if(!portal_identity_validate_session(true)||!portal_identity_has_workspace()){http_response_code(401);echo json_encode(['error'=>'unauthorized']);exit;}
	if((string)($_SESSION['portal_identity']['membership']['role']??'')!=='owner'){http_response_code(403);echo json_encode(['error'=>'owner_required']);exit;}
	if(($_SERVER['REQUEST_METHOD']??'')==='GET'){
		$id=(string)($_GET['id']??'');$view=portal_call_routing_customer_request(['action'=>'customer_routing_view']);
		$allowed=array_filter((array)($view['payload']['recordings']??[]),fn($row)=>($row['recording_uuid']??'')===$id);
		if(!is_uuid($id)||count($allowed)!==1){http_response_code(404);echo json_encode(['error'=>'recording_not_found']);exit;}
		$row=array_values($allowed)[0];$path=rtrim((string)$settings->get('switch','recordings'),'/').'/'.$_SESSION['domain_name'].'/'.basename($row['recording_filename']);
		if(!is_file($path)){http_response_code(404);echo json_encode(['error'=>'recording_missing']);exit;}
		header('Content-Type: audio/wav');header('Content-Length: '.filesize($path));readfile($path);exit;
	}
	if(($_SERVER['REQUEST_METHOD']??'')!=='POST'){http_response_code(405);echo json_encode(['error'=>'method_not_allowed']);exit;}
	$provided=(string)($_SERVER['HTTP_X_CSRF_TOKEN']??'');$expected=(string)($_SESSION['portal']['csrf']??'');
	if($provided===''||$expected===''||!hash_equals($expected,$provided)){http_response_code(403);echo json_encode(['error'=>'invalid_csrf']);exit;}
	$file=$_FILES['audio']??null;$name=trim((string)($_POST['name']??''));
	if(!is_array($file)||($file['error']??UPLOAD_ERR_NO_FILE)!==UPLOAD_ERR_OK||($file['size']??0)<1||$file['size']>10*1024*1024||$name===''){
		http_response_code(400);echo json_encode(['error'=>'invalid_audio']);exit;
	}
	$mime=(new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']);
	if(!in_array($mime,['audio/wav','audio/x-wav','audio/mpeg','audio/ogg','application/ogg'],true)){http_response_code(422);echo json_encode(['error'=>'unsupported_audio']);exit;}
	$probe=[];$probe_code=0;exec('/usr/bin/ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 '.escapeshellarg($file['tmp_name']),$probe,$probe_code);
	$duration=(float)($probe[0]??0);if($probe_code!==0||$duration<=0||$duration>300){http_response_code(422);echo json_encode(['error'=>'invalid_audio_duration']);exit;}
	$recording_uuid=uuid();$filename='mphone-'.$recording_uuid.'.wav';$directory=rtrim((string)$settings->get('switch','recordings'),'/').'/'.$_SESSION['domain_name'];
	if(!is_dir($directory)&&!mkdir($directory,0770,true)){http_response_code(503);echo json_encode(['error'=>'recording_storage_unavailable']);exit;}
	$target=$directory.'/'.$filename;$output=[];$code=0;
	exec('/usr/bin/ffmpeg -nostdin -v error -y -i '.escapeshellarg($file['tmp_name']).' -ac 1 -ar 8000 -c:a pcm_s16le '.escapeshellarg($target),$output,$code);
	if($code!==0||!is_file($target)){http_response_code(422);echo json_encode(['error'=>'audio_normalization_failed']);exit;}
	try{
		$array['recordings'][0]=['recording_uuid'=>$recording_uuid,'domain_uuid'=>$_SESSION['domain_uuid'],'recording_filename'=>$filename,
			'recording_name'=>mb_substr($name,0,100),'recording_description'=>'Managed by Mphone Customer Portal','insert_date'=>date('c'),'insert_user'=>$_SESSION['user_uuid']];
		$p=permissions::new();$p->add('recording_add','temp');$saved=$database->save($array);$p->delete('recording_add','temp');
		if($saved===false)throw new RuntimeException('recording_save_failed');
		$result=portal_call_routing_customer_request(['action'=>'customer_register_recording','recording_uuid'=>$recording_uuid,
			'fusion_domain_uuid'=>$_SESSION['domain_uuid'],'recording_filename'=>$filename]);
		if(!in_array($result['status'],[200,201],true))throw new RuntimeException($result['payload']['error']??'recording_registration_failed');
		echo json_encode(['recording_uuid'=>$recording_uuid,'recording_name'=>$name,'recording_filename'=>$filename]);
	}catch(Throwable $error){@unlink($target);$database->execute('delete from v_recordings where recording_uuid=:uuid and domain_uuid=:domain_uuid',['uuid'=>$recording_uuid,'domain_uuid'=>$_SESSION['domain_uuid']]);http_response_code(503);echo json_encode(['error'=>$error->getMessage()]);}
?>
