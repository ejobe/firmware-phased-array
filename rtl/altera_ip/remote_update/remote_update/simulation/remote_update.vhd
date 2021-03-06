-- remote_update.vhd

-- Generated using ACDS version 15.1 185

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity remote_update is
	port (
		asmi_addr       : out std_logic_vector(31 downto 0);                    --       asmi_addr.asmi_addr
		asmi_busy       : in  std_logic                     := '0';             --       asmi_busy.asmi_busy
		asmi_data_valid : in  std_logic                     := '0';             -- asmi_data_valid.asmi_data_valid
		asmi_dataout    : in  std_logic_vector(7 downto 0)  := (others => '0'); --    asmi_dataout.asmi_dataout
		asmi_rden       : out std_logic;                                        --       asmi_rden.asmi_rden
		asmi_read       : out std_logic;                                        --       asmi_read.asmi_read
		busy            : out std_logic;                                        --            busy.busy
		clock           : in  std_logic                     := '0';             --           clock.clk
		data_in         : in  std_logic_vector(31 downto 0) := (others => '0'); --         data_in.data_in
		data_out        : out std_logic_vector(31 downto 0);                    --        data_out.data_out
		param           : in  std_logic_vector(2 downto 0)  := (others => '0'); --           param.param
		pof_error       : out std_logic;                                        --       pof_error.pof_error
		read_param      : in  std_logic                     := '0';             --      read_param.read_param
		reconfig        : in  std_logic                     := '0';             --        reconfig.reconfig
		reset           : in  std_logic                     := '0';             --           reset.reset
		reset_timer     : in  std_logic                     := '0';             --     reset_timer.reset_timer
		write_param     : in  std_logic                     := '0'              --     write_param.write_param
	);
end entity remote_update;

architecture rtl of remote_update is
	component remote_update_remote_update_0 is
		port (
			busy            : out std_logic;                                        -- busy
			data_out        : out std_logic_vector(31 downto 0);                    -- data_out
			param           : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- param
			read_param      : in  std_logic                     := 'X';             -- read_param
			reconfig        : in  std_logic                     := 'X';             -- reconfig
			reset_timer     : in  std_logic                     := 'X';             -- reset_timer
			write_param     : in  std_logic                     := 'X';             -- write_param
			data_in         : in  std_logic_vector(31 downto 0) := (others => 'X'); -- data_in
			clock           : in  std_logic                     := 'X';             -- clk
			reset           : in  std_logic                     := 'X';             -- reset
			asmi_busy       : in  std_logic                     := 'X';             -- asmi_busy
			asmi_data_valid : in  std_logic                     := 'X';             -- asmi_data_valid
			asmi_dataout    : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- asmi_dataout
			asmi_addr       : out std_logic_vector(31 downto 0);                    -- asmi_addr
			asmi_read       : out std_logic;                                        -- asmi_read
			asmi_rden       : out std_logic;                                        -- asmi_rden
			pof_error       : out std_logic                                         -- pof_error
		);
	end component remote_update_remote_update_0;

begin

	remote_update_0 : component remote_update_remote_update_0
		port map (
			busy            => busy,            --            busy.busy
			data_out        => data_out,        --        data_out.data_out
			param           => param,           --           param.param
			read_param      => read_param,      --      read_param.read_param
			reconfig        => reconfig,        --        reconfig.reconfig
			reset_timer     => reset_timer,     --     reset_timer.reset_timer
			write_param     => write_param,     --     write_param.write_param
			data_in         => data_in,         --         data_in.data_in
			clock           => clock,           --           clock.clk
			reset           => reset,           --           reset.reset
			asmi_busy       => asmi_busy,       --       asmi_busy.asmi_busy
			asmi_data_valid => asmi_data_valid, -- asmi_data_valid.asmi_data_valid
			asmi_dataout    => asmi_dataout,    --    asmi_dataout.asmi_dataout
			asmi_addr       => asmi_addr,       --       asmi_addr.asmi_addr
			asmi_read       => asmi_read,       --       asmi_read.asmi_read
			asmi_rden       => asmi_rden,       --       asmi_rden.asmi_rden
			pof_error       => pof_error        --       pof_error.pof_error
		);

end architecture rtl; -- of remote_update
