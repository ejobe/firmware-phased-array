	component remote_update is
		port (
			busy        : out std_logic;                                        -- busy
			clock       : in  std_logic                     := 'X';             -- clk
			data_in     : in  std_logic_vector(31 downto 0) := (others => 'X'); -- data_in
			data_out    : out std_logic_vector(31 downto 0);                    -- data_out
			param       : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- param
			read_param  : in  std_logic                     := 'X';             -- read_param
			reconfig    : in  std_logic                     := 'X';             -- reconfig
			reset       : in  std_logic                     := 'X';             -- reset
			reset_timer : in  std_logic                     := 'X';             -- reset_timer
			write_param : in  std_logic                     := 'X'              -- write_param
		);
	end component remote_update;

	u0 : component remote_update
		port map (
			busy        => CONNECTED_TO_busy,        --        busy.busy
			clock       => CONNECTED_TO_clock,       --       clock.clk
			data_in     => CONNECTED_TO_data_in,     --     data_in.data_in
			data_out    => CONNECTED_TO_data_out,    --    data_out.data_out
			param       => CONNECTED_TO_param,       --       param.param
			read_param  => CONNECTED_TO_read_param,  --  read_param.read_param
			reconfig    => CONNECTED_TO_reconfig,    --    reconfig.reconfig
			reset       => CONNECTED_TO_reset,       --       reset.reset
			reset_timer => CONNECTED_TO_reset_timer, -- reset_timer.reset_timer
			write_param => CONNECTED_TO_write_param  -- write_param.write_param
		);

