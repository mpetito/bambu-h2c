;===== machine: H2C =========================
;===== date: 20251210 =====================

;M1002 set_flag extrude_cali_flag=1
;M1002 set_flag g29_before_print_flag=1
;M1002 set_flag auto_cali_toolhead_offset_flag=1
;M1002 set_flag build_plate_detect_flag=1

M993 A0 B0 C0 ; nozzle cam detection not allowed.

M400
;M73 P99

M960 S10 P1 ; ext fan led

;=====printer start sound ===================
M17
M400 S1
M1006 S1
M1006 A53 B9 L99 C53 D9 M99 E53 F9 N99 
M1006 A56 B9 L99 C56 D9 M99 E56 F9 N99 
M1006 A61 B9 L99 C61 D9 M99 E61 F9 N99 
M1006 A53 B9 L99 C53 D9 M99 E53 F9 N99 
M1006 A56 B9 L99 C56 D9 M99 E56 F9 N99 
M1006 A61 B18 L99 C61 D18 M99 E61 F18 N99 
M1006 W
;=====printer start sound ===================

;===== reset machine status =================
M204 S10000
M630 S0 P0

G90
M17 D ; reset motor current to default
M960 S5 P1 ; turn on logo lamp
G90
M1002 set_gcode_claim_speed_level 5 ;Reset speed level
M220 S100 ;Reset Feedrate
M221 S100 ;Reset Flowrate
M73.2   R1.0 ;Reset left time magnitude
G29.1 Z{+0.0} ; clear z-trim value first
M983.1 M1 
M901 D4
M481 S0 ; turn off cutter pos comp
G28.140 D0; reset pre-extrude z pos
;===== reset machine status =================

M620 M ;enable remap
M620 N ;enable hotend remap
M620 T0 ;print tmpr
M620 T1 ;sn -> pos
M620 T2 ;filament_id

;===== start to heat heatbed & hotend==========

    M104 O-80 A
    M140 D[bed_temperature_initial_layer_single]

;===== start to heat heatbead & hotend==========

;===== avoid end stop =================
G91
G380 S2 Z42 F1200
G380 S2 Z-12 F1200
G90
;===== avoid end stop =================

;==== set airduct mode ==== 

{if (overall_chamber_temperature >= 40)}

    M145 P1 ; set airduct mode to heating mode for heating
    M106 P2 S0 ; turn off auxiliary fan
    M106 P3 S0 ; turn off chamber fan

{else}
    M145 P0 ; set airduct mode to cooling mode for cooling
    M106 P2 S178 ; turn on auxiliary fan for cooling
    M106 P3 S127 ; turn on chamber fan for cooling

    M1002 gcode_claim_action : 29
    M191 S0 ; wait for chamber temp
    M106 P2 S0 ; turn off auxiliary fan
    {if (min_vitrification_temperature <= 50)}
        {if (nozzle_diameter == 0.2)}
            M142 P1 R30 S35 T40 U0.3 V0.5 W0.8 O40 ; set PLA/TPU ND0.2 chamber autocooling
        {else}
            M142 P1 R30 S40 T45 U0.3 V0.5 W0.8 O45; set PLA/TPU ND0.4 chamber autocooling
        {endif}
    {else}
        {if (!is_all_bbl_filament)}
            M142 P1 R35 S40 T45 U0.3 V0.5 W0.8 O45 L1 ; set third-party PETG chamber autocooling
        {else}
            {if (nozzle_diameter == 0.2)}
                M142 P1 R35 S45 T50 U0.3 V0.5 W0.8 O50 L1 ; set PETG ND0.2 chamber autocooling
            {else}
                M142 P1 R35 S50 T55 U0.3 V0.5 W0.8 O55 L1 ; set PETG ND0.4 chamber autocooling
            {endif}
        {endif}
    {endif}
{endif}
;==== set airduct mode ==== 


;====== cog noise reduction=================
M982.2 S1 ; turn on cog noise reduction

;===== first homing start =====
M1002 gcode_claim_action : 13

M640 S
M640.1 R
M641
G28 X T300
T1000

G150.3
M972 S24 P0 T2000 ; live-view camera foolproof
M972 S46 P0 T5000 ; vortek anti-collision
M640.1 S
M640.4
{if (first_non_support_filaments[0] != -1)}
M640 S
M640.8 T A{first_non_support_filaments[0]}
M640.7 L
M641
{endif}


{if wipe_tower_center_pos_valid}
    M620.14 X[wipe_tower_center_pos_x] Y[wipe_tower_center_pos_y]
{else}
    M620.14 X95.5 Y336
{endif}


G150.1 F18000 ; wipe mouth to avoid filament stick to heatbed
G150.3 F18000
M400 P200

{if curr_bed_type=="Textured PEI Plate"}
M972 S26 P0 C0
{else}
M972 S36 P0 C0 X1
{endif}
M972 S35 P0 C0

M972 S41 P0 T5000 ; trash can anti-collision

M1009 Q1 L1
G90
G1 X175 Y160 F30000
G28 Z P0 T250
M1009 Q1 L0


;===== first homing end =====

M104 O-80 A

;===== detection start =====
    

M1002 judge_flag build_plate_detect_flag
M622 S1
    M972 S19 P0 C0    ; heatbed presence detection
    M972 S31 P0 T5000 ; toolhead camera dirty detection
    M972 S34 P0 T5000 ; heatbed plate offset detection
M623

T1001
M972 S14 P0 T5000 ; nozzle type detection

M104 O-80 A ; rise temp in advance

;===== detection end =====

M400
;M73 P99

;===== prepare print temperature and material ==========
M400
M211 X0 Y0 Z0 ;turn off soft endstop
M975 S1 ; turn on input shaping

G29.2 S0 ; avoid invalid abl data

{if ((filament_type[initial_no_support_extruder] == "PLA") || (filament_type[initial_no_support_extruder] == "PLA-CF") || (filament_type[initial_no_support_extruder] == "PETG")) && (nozzle_diameter[initial_no_support_extruder] == 0.2)}
M620.10 A0 F74.8347 H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
M620.10 A1 F74.8347 H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
{else}
M620.10 A0 F{flush_volumetric_speeds[initial_no_support_extruder]/2.4053*60*0.8} H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
M620.10 A1 F{flush_volumetric_speeds[initial_no_support_extruder]/2.4053*60*0.8} H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
{endif}

M620.11 P1 I[initial_no_support_extruder] E0

{if long_retraction_when_ec }
M620.11 K1 I[initial_no_support_extruder] R{retraction_distance_when_ec} F{max((flush_volumetric_speeds[initial_no_support_extruder]/2.4053*60), 200)}
{else}
M620.11 K0 I[initial_no_support_extruder] R0
{endif}

M628 S1
{if filament_type[initial_no_support_extruder] == "TPU"}
    M620.11 S0 L0 I[initial_no_support_extruder] E-{retraction_distances_when_cut[initial_no_support_extruder]} F{flush_volumetric_speeds[initial_no_support_extruder]/2.4053*60}
{else}
{if (filament_type[initial_no_support_extruder] == "PA") ||  (filament_type[initial_no_support_extruder] == "PA-GF")}
    M620.11 S1 L0 I[initial_no_support_extruder] R4 D2 E-{retraction_distances_when_cut[initial_no_support_extruder]} F{flush_volumetric_speeds[initial_no_support_extruder]/2.4053*60}
{else}
    M620.11 S1 L0 I[initial_no_support_extruder] R10 D8 E-{retraction_distances_when_cut[initial_no_support_extruder]} F{flush_volumetric_speeds[initial_no_support_extruder]/2.4053*60}
{endif}
{endif}
M629

M620 S[initial_no_support_extruder]A   ; switch material if AMS exist
M1002 gcode_claim_action : 4
M1002 set_filament_type:UNKNOWN
M400
T[initial_no_support_extruder]
M400
M628 S0
M629
M400
M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
M621 S[initial_no_support_extruder]A

M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]}
M400
M106 P1 S0

G91
G1 Y-16 F60000
G90

G29.2 S1
;===== prepare print temperature and material ==========


M400
;M73 P99

;===== xy ofst cali start =====

M1002 judge_flag auto_cali_toolhead_offset_flag

M622 J2
    M1002 gcode_claim_action : 54
    M190 D[bed_temperature_initial_layer_single]
    
    M1002 gcode_claim_action : 39
    G383.3 U140 L{initial_no_support_extruder}
    M500
M623

M622 J1
    M1002 gcode_claim_action : 54
    M190 D[bed_temperature_initial_layer_single]

    M1002 gcode_claim_action : 39
    G383 O2 U140 L{initial_no_support_extruder}
    M500
M623

;===== xy ofst cali end =====

;===== start to heat heatbed & hotend==========

    M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
    G150.3
    M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]}
    M140 S[bed_temperature_initial_layer_single]

    ;===== set chamber temperature ==========
    {if (overall_chamber_temperature >= 40)}
        M145 P1 ; set airduct mode to heating mode
        M141 S[overall_chamber_temperature] ; Let Chamber begin to heat
    {endif}
    ;===== set chamber temperature ==========

;===== start to heat heatbead & hotend==========



M400
;M73 P99

;===== auto extrude cali start =========================
M975 S1
M1002 judge_flag extrude_cali_flag

M622 J0
    M983.3 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4} A0.4 ; cali dynamic extrusion compensation
M623

M622 J1
    M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
    M1002 gcode_claim_action : 8

    M109 S{nozzle_temperature[initial_no_support_extruder]}

    G90
    M83
    M983.3 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4} A0.4 ; cali dynamic extrusion compensation

    M400
    M106 P1 S255
    M400 S5
    M106 P1 S0
    G150.3
M623

M622 J2
    M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
    M1002 gcode_claim_action : 8

    M109 S{nozzle_temperature[initial_no_support_extruder]}

    G90
    M83
    M983.3 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4} A0.4 ; cali dynamic extrusion compensation

    M400
    M106 P1 S255
    M400 S5
    M106 P1 S0
    G150.3
M623

;===== auto extrude cali end =========================

{if filament_type[initial_no_support_extruder] == "TPU"}
    G150.2
    G150.1
    G150.2
    G150.1
    G150.2
    G150.1
{else}
    G150.3
    M106 P1 S0
    M400 S2
    M109 S{nozzle_temperature[initial_no_support_extruder]} ; wait tmpr to extrude
    M83
    {if(nozzle_diameter == 0.8)}
        G1 E60 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4053*60}
    {else}
        G1 E45 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4053*60}
    {endif}
    G1 E-3 F1800
    M400 P500
    G150.2
    G150.1
{endif}

G91
G1 Y-16 F12000 ; move away from the trash bin
G90

M400
;M73 P99

;===== wipe right nozzle start =====

M1002 gcode_claim_action : 14
    G150 T{nozzle_temperature_initial_layer[initial_no_support_extruder]}
    {if (overall_chamber_temperature >= 40)}
        G150 T{nozzle_temperature_initial_layer[initial_no_support_extruder] - 80}
    {endif}
M106 S255 ; turn on fan to cool the nozzle

;===== wipe left nozzle end =====

M400
;M73 P99

M1002 judge_flag auto_cali_toolhead_offset_flag
M622 J0
    G91
    G1 Z5 F1200
    G90
    M1012.7
    G383.7 U140 J0
    M500
M623

{if (overall_chamber_temperature >= 40)}
    M1002 gcode_claim_action : 49
    M191 S[overall_chamber_temperature] ; wait for chamber temp
{endif}

M400
;M73 P99

;===== bed leveling ==================================

M1002 judge_flag g29_before_print_flag

M190 S[bed_temperature_initial_layer_single]; ensure bed temp
M109 S140 A
M106 S0 ; turn off fan , too noisy

G91
G1 Z10 F1200
{if (first_non_support_filaments[0] != -1)}
M640 S
M83
G1 E-2 F1800
M640.7 U
M640.7 L
M640.2 R1
M641
{endif}
G90
G1 X175 Y160 F30000

M622 J1
    M1002 gcode_claim_action : 1
    G29.20 A3
    G29 A1 O X{first_layer_print_min[0]} Y{first_layer_print_min[1]} I{first_layer_print_size[0]} J{first_layer_print_size[1]} R 
    M400
    M500 ; save cali data
M623
    
M622 J2
    M1002 gcode_claim_action : 1
    {if has_tpu_in_first_layer}
        G29.20 A3
        G29 A1 O X{first_layer_print_min[0]} Y{first_layer_print_min[1]} I{first_layer_print_size[0]} J{first_layer_print_size[1]} R
    {else}
        G29.20 A4
        G29 A2 O X{first_layer_print_min[0]} Y{first_layer_print_min[1]} I{first_layer_print_size[0]} J{first_layer_print_size[1]} R
    {endif}
    M400
    M500 ; save cali data
M623

M622 J0
    G28 R
M623

;===== bed leveling end ================================

G39.1 ; cali nozzle wrapped detection pos
M500

G90
G1 Z5 F1200
G1 X270 Y-0.5 F60000
G28.140 S0 ; cali pre-extrude z pos

;============switch again==================

M211 X0 Y0 Z0 ;turn off soft endstop
G91
G1 Z6 F1200
G90
M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
M620 S[initial_no_support_extruder]A
M400
T[initial_no_support_extruder]
M400
M628 S0
M629
M400
M621 S[initial_no_support_extruder]A

;============switch again==================

M400
;M73 P99

M141 S[overall_chamber_temperature]

;===== mech mode sweep start =====
    M1002 gcode_claim_action : 3

    G90
    G1 Z5 F1200
    G1 X165 Y160 F20000
    M400 P200

    M970.3 Q1 A5 K0 O1
    M974 Q1 S2 P0

    M970.3 Q0 A5 K0 O1
    M974 Q0 S2 P0

    M970.2 Q2 K0 W38 Z0.01
    M974 Q2 S2 P0
    M500

    M975 S1
;===== mech mode sweep end =====

;===== wait temperature reaching the reference value =======

M140 S[bed_temperature_initial_layer_single] 
M190 S[bed_temperature_initial_layer_single] 

    ;========turn off light and fans =============
    M960 S1 P0 ; turn off laser
    M960 S2 P0 ; turn off laser
    M106 S0 ; turn off fan
    M106 P2 S0 ; turn off big fan
    ;==== set ext toodhead cooling fan ==== 
    {if (min_vitrification_temperature <= 50)}
    M106 P9 S255
    {endif}
    ;============set motor current==================
    M400 S1

;===== wait temperature reaching the reference value =======

M400
;M73 P99

;===== for Textured PEI Plate , lower the nozzle as the nozzle was touching topmost of the texture when homing ==
    {if curr_bed_type=="Textured PEI Plate"
      && !((filament_type[initial_no_support_extruder] == "PCTG") || (filament_type[initial_no_support_extruder] == "PCTG-CF")) 
    } ; unless PCTG which needs some extra space for first layer extrusion
        G29.1 Z{-0.02} ; for Textured PEI Plate
    {endif}
    
G150.1

M975 S1 ; turn on mech mode supression
M983.4 S1 ; turn on deformation compensation 
G29.2 S1 ; turn on pos comp
G29.7 S1

G90
G1 Z5 F1200
G1 Y295 F30000
G1 Y265 F18000

;===== nozzle load line ===============================
    G29.2 S1 ; ensure z comp turn on
    G90
    M83
    G1 Z5 F1200
    G1 X270 Y-0.5 F60000
    G28.14 R0
    G29.2 S0
    G91
    G1 Z0.8 F1200
    G90
    G1 X250 F60000
    M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]}
    
    ========== record data ==========
    M1026
    M1012.8
    M1012.9
    G29.9
    ========== record data ==========
    
    M109 S{nozzle_temperature_initial_layer[initial_no_support_extruder]}
    M83
    G1 E5 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4053*60}
    G1 X290 E10 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4053*4*60}
    G91
    G3 Z0.4 I1.217 J0 P1 F60000
    G90
    M83
    G29.2 S1 ; ensure z comp turn on
;===== noozle load line end ===========================

M400
;M73 P99

M993 A1 B1 C1 ; nozzle cam detection allowed.

{if (filament_type[initial_no_support_extruder] == "TPU")}
M1015.3 S1;enable tpu clog detect
{else}
M1015.3 S0;disable tpu clog detect
{endif}

{if (filament_type[initial_no_support_extruder] == "PLA") ||  (filament_type[initial_no_support_extruder] == "PETG")
 || (filament_type[initial_no_support_extruder] == "PCTG") || (filament_type[initial_no_support_extruder] == "PCTG-CF")
 ||  (filament_type[initial_no_support_extruder] == "PLA-CF")  ||  (filament_type[initial_no_support_extruder] == "PETG-CF")}
M1015.4 S1 K1 H[nozzle_diameter] ;enable E air printing detect
{else}
M1015.4 S0 K0 H[nozzle_diameter] ;disable E air printing detect
{endif}

M620.6 I[initial_no_support_extruder] W1 ;enable ams air printing detect

M211 Z1
G29.99
M1002 gcode_claim_action : 0
M400


