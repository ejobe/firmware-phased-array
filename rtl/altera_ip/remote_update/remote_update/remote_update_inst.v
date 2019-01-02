	remote_update u0 (
		.busy        (<connected-to-busy>),        //        busy.busy
		.clock       (<connected-to-clock>),       //       clock.clk
		.data_in     (<connected-to-data_in>),     //     data_in.data_in
		.data_out    (<connected-to-data_out>),    //    data_out.data_out
		.param       (<connected-to-param>),       //       param.param
		.read_param  (<connected-to-read_param>),  //  read_param.read_param
		.reconfig    (<connected-to-reconfig>),    //    reconfig.reconfig
		.reset       (<connected-to-reset>),       //       reset.reset
		.reset_timer (<connected-to-reset_timer>), // reset_timer.reset_timer
		.write_param (<connected-to-write_param>)  // write_param.write_param
	);

