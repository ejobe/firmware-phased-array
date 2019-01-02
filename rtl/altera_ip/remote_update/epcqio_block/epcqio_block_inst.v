	epcqio_block u0 (
		.clkin         (<connected-to-clkin>),         //         clkin.clk
		.read          (<connected-to-read>),          //          read.read
		.rden          (<connected-to-rden>),          //          rden.rden
		.addr          (<connected-to-addr>),          //          addr.addr
		.reset         (<connected-to-reset>),         //         reset.reset
		.dataout       (<connected-to-dataout>),       //       dataout.dataout
		.busy          (<connected-to-busy>),          //          busy.busy
		.data_valid    (<connected-to-data_valid>),    //    data_valid.data_valid
		.write         (<connected-to-write>),         //         write.write
		.datain        (<connected-to-datain>),        //        datain.datain
		.illegal_write (<connected-to-illegal_write>), // illegal_write.illegal_write
		.wren          (<connected-to-wren>),          //          wren.wren
		.shift_bytes   (<connected-to-shift_bytes>),   //   shift_bytes.shift_bytes
		.bulk_erase    (<connected-to-bulk_erase>),    //    bulk_erase.bulk_erase
		.illegal_erase (<connected-to-illegal_erase>), // illegal_erase.illegal_erase
		.sector_erase  (<connected-to-sector_erase>),  //  sector_erase.sector_erase
		.read_address  (<connected-to-read_address>),  //  read_address.read_address
		.en4b_addr     (<connected-to-en4b_addr>)      //     en4b_addr.en4b_addr
	);

