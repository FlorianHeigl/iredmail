<?php
function smarty_function_IRA_vmenulink($params, &$smarty) {
    if (empty($params['var'])) {
        $smarty->trigger_error('IRA_vmenulink: missing "" parameter!');
    }
    if (empty($params['href'])) {
        $smarty->trigger_error('IRA_vmenulink: missing "href" parameter!');
    }
    if (empty($params['text'])) {
        $smarty->trigger_error('IRA_vmenulink: missing "text" parameter!');
    }
    
    $submenu = $params['submenu'];
    if (!empty($submenu)) {
        $submenu = '<ul><li><a href="'.$params['href'].'" target="_top">'.$params['text'].'</a>'.$submenu.'</li></ul>';
    }
    $submenu = '<ul><li><a href="'.$params['href'].'" target="_top">'.$params['text'].'</a>'.$submenu.'</li></ul>';

    $smarty->assign($params['var'], $submenu);
}
?>
