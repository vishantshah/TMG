/* Creating DCSext meta tag to track users who are logged in */
if($.cookie("tmg_pid")) {
	$("head").append($("<meta />").attr("name","wt.dcsvid").attr("content",$.cookie("tmg_pid")));
}
