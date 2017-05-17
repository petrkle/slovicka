var classname = document.getElementsByClassName("fis");

var preklad = function() {
    var translation = this.getAttribute("data-translation");
		var text = this.textContent;
		this.textContent = translation;
		this.setAttribute("data-translation", text);
		if (this.className === "fis") {
			this.className = "fis-vybrane";
		}else{
			this.className = "fis";
		}
};

for (var i = 0; i < classname.length; i++) {
    classname[i].addEventListener('click', preklad, false);
}
