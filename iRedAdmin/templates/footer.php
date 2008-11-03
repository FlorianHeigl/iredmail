<div id="footer">
<a target="_blank" href="http://www.iredmail.org/">iRedAdmin <[[$version]]></a>
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
<[[if isset($smarty.session.sessid.username)]]>
<[[$logged_in_as]]>
<[[/if]]>
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
<[[if $CONF.show_footer_text == 'YES' and !empty($CONF.footer_link)]]>
&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
<a href="<[[$CONF.footer_link]]>"><[[$CONF.footer_text]]></a>
<[[/if]]>
</div>
</body>
</html>
