var classname = document.getElementsByClassName("flex-item-slovicko");

var preklad = function() {
    var translation = this.getAttribute("data-translation");
		var text = this.textContent;
		this.textContent = translation;
		this.setAttribute("data-translation", text);
};

for (var i = 0; i < classname.length; i++) {
    classname[i].addEventListener('click', preklad, false);
}
