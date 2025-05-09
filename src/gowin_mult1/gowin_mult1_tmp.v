//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.11
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Thu Apr 24 23:36:41 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_MULT1 your_instance_name(
        .dout(dout), //output [19:0] dout
        .a(a), //input [9:0] a
        .b(b), //input [9:0] b
        .ce(ce), //input ce
        .clk(clk), //input clk
        .reset(reset) //input reset
    );

//--------Copy end-------------------
