<?php

	$apps[$x]['name'] = 'Customer Identities';
	$apps[$x]['uuid'] = '3c2d96fd-7d8f-4bb4-a235-30647c46c0bd';
	$apps[$x]['category'] = 'Accounts';
	$apps[$x]['subcategory'] = '';
	$apps[$x]['version'] = '1.0';
	$apps[$x]['license'] = 'Mozilla Public License 1.1';
	$apps[$x]['url'] = 'https://mphone.vn';
	$apps[$x]['description']['en-us'] = 'Manage Customer Identity memberships and Extension assignments.';
	$apps[$x]['description']['vi-vn'] = 'Quản lý Customer Identity, Membership và phân quyền máy nhánh.';

	$y = 0;
	$apps[$x]['permissions'][$y]['name'] = 'customer_identity_view';
	$apps[$x]['permissions'][$y]['groups'][] = 'superadmin';
	$y++;
	$apps[$x]['permissions'][$y]['name'] = 'customer_identity_edit';
	$apps[$x]['permissions'][$y]['groups'][] = 'superadmin';

?>
