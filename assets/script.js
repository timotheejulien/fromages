function mailTo() {
	var $mailToEmail = "email@timotheejulien.fr";
	var $mailToSubject = "Notes caséologiques : prise de contact";
	window.location.href='mailto:'+$mailToEmail+'?subject='+$mailToSubject;
}

function search_modal() {
	el = document.getElementById("search_modal");
	el.style.visibility = (el.style.visibility == "visible") ? "hidden" : "visible";
	document.getElementById("search-input").focus();
}

document.addEventListener("keydown", function(event) {  
   if (event.key === "Escape") {  
       let input = document.getElementById("search-input");  
       if (input) {
           input.value = ""; // Efface le contenu de l'input
       }
       search_modal();  
   }  
});
