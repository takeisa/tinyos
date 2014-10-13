open Core.Std

let file_name = "hankaku.txt"

exception Illegal_format of string

let is_skip_line line =
  let line' = String.strip line in
  line' = "" || String.get line 0 = '#'

let is_char_line line =
  try
    String.slice line 0 4 = "char"
  with
    _ -> false

let pattern_to_int p =
  String.fold p ~init:0 ~f:(fun acc c ->
      (acc lsl 1) + (if c = '*' then 1 else 0))

type parse_state = Init | Read_header | Read_data

let () =
  let lines = In_channel.read_lines file_name in
  let state = ref Init in
  List.iter lines ~f:(fun line ->
      if not (is_skip_line line) then
        if is_char_line line then begin
          if !state = Read_data then
            print_newline ();
          state := Read_header;
          print_endline ("\t// " ^ line);
          print_string "\t.byte "
        end
        else begin
          if !state = Read_data then
            print_string ",";
          state := Read_data;
          let img = pattern_to_int line in
          print_string ("0x" ^ (Printf.sprintf "%02x" img));
        end
    );
  print_newline ()

