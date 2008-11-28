<?php
function smarty_function_IRA_domainlink($params, &$smarty) {
    if (empty($params['var'])) {
        $smarty->trigger_error("IRA_domainlink: missing 'var' parameter!");
        return;
    }

    if (empty($params['href'])) {
        $smarty->trigger_error("IRA_domainlink: missing 'href' parameter!");
        return;
    }

    $url = $params['href'];
    if (isset($_GET['domain'])) {
        if (strpos($url, '?') === false) {
            $url .= "?domain=" . $_GET['domain'];
        } else {
            $url .= "&domain=" . $_GET['domain'];
        }
    }

    $smarty->assign($params['var'], $url);
}
?>
