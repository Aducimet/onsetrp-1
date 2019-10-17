$(document).ready(function() {

	$("#buy").click(function() {
		price = $(".badge-danger").text();
		badname = $(".badge-danger").parent("a").contents().filter(function() {
			return this.nodeType == 3; // text node
		});
		name = badname.text()
		modelid = $(".badge-danger").parent("a").attr("id")
		CallEvent("buyCar", price, name, modelid);
		$("a").find("span").removeClass("badge-danger").addClass("badge-primary")
	});

	$("#close").click(function() {

		CallEvent("closeCarDealer");
	});
});


function addCarList(modelid, name, price) {
	let object = '<a href="#" id="'+ modelid +'" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center" onclick="selectCar(this)">' + name + '<span class="badge badge-primary badge-pill">' + price + '$</span></a>';
	$('#carList').append(object);
}

function selectCar(object) {
	$("a").not(object).find("span").removeClass("badge-danger").addClass("badge-primary")
	$(object).find("span").removeClass("badge-primary").addClass("badge-danger")
}