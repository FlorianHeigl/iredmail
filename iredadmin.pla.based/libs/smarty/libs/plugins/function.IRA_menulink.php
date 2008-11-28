<?php
function smarty_function_IRA_menulink($params, &$smarty) {
    if (empty($params['href'])) {
        $smarty->trigger_error('IRA_menulink: missing "href" parameter!');
    }
    if (empty($params['text'])) {
        $smarty->trigger_error('IRA_menulink: missing "text" parameter!');
    }
    
    $submenu = $params['submenu'];
    if (!empty($submenu)) {
        $submenu = '<ul><li><a href="'.$params['href'].'" target="_top">'.$params['text'].'</a>'.$submenu.'</li></ul>';
    }
    return '<ul><li><a href="'.$params['href'].'" target="_top">'.$params['text'].'</a>'.$submenu.'</li></ul>';
}
?>
