component {

	this.name = "cfc_loader_tests";
	this.mappings = {
		"/": ExpandPath("./") // fixes issue with prefix added to test CFC paths
	};

}