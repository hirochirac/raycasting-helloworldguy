package helloworldguy

import "core:fmt"
import "core:os"
import "core:math"
import "core:bytes"
import "core:strings"
import rl "vendor:raylib"


Item :: enum {
    Wall,
    Ground,
    Player,
    Rayon,
}

items : [Item]rl.Color = {
    .Wall = rl.GRAY,
    .Ground = rl.BROWN,
    .Player = rl.RED,
    .Rayon = rl.GREEN
}


SCREEN_WIDTH :: 1000
SCREEN_HEIGHT :: 800
TITLE :: "Raycasting Helloworld"
TILE_SIZE :: 32

Player :: struct {
    x: int,
    y: int,
    position: rl.Vector2,
    circle_size: f32,
    angle: f32,
    angle_rotation: f32,
    move_speed: f32,
    ray_lenght: f32,
    rays: [dynamic]rl.Ray,
    fov: f32,
    number_of_ray: i32,
}


init_player :: proc ( x : int = 2, y : int =  2,
                     circle_size: f32 = 5.0,
                     angle : f32 = 90.0,
                     angle_rotation : f32 = 5.0,
                     move_speed : f32 = 10.0,
                     ray_lenght : f32 = 200.0, fov: f32 = 60.0, number_of_ray: i32 = 100 ) -> (player: Player) {
    player.x = x
    player.x = y
    player.circle_size = circle_size
    player.position.x = f32(x * TILE_SIZE)
    player.position.y = f32(y * TILE_SIZE)
    player.angle = angle
    player.angle_rotation = angle_rotation
    player.move_speed = move_speed
    player.ray_lenght = ray_lenght
    player.fov = 60
    player.number_of_ray = number_of_ray
    player.rays = make_dynamic_array_len([dynamic]rl.Ray,number_of_ray+1)
    return 
}

get_carte :: proc (carte_file_path: string, $COL, $LIG: int,  allocator := context.allocator) -> ( carte: [COL][LIG]rune, success: bool ) {
    
    handle, error := os.open(carte_file_path,os.O_RDONLY)
    file, ok := os.read_entire_file_from_handle(handle,allocator)

    for c in 0..< COL {
        for l in 0 ..< LIG {
            indice := c * COL + l
            carte[c][l] = rune(u8(file[indice]))
        }
    }
    
    delete_slice(file)
    os.close(handle)
    return
}


fix_angle :: proc ( a : f32 ) -> ( angle: f32 ) {
    angle = a
    if ( angle < 0 ) {
        angle += 360
    } else if angle >= 360 {
        angle -= 360
    }
    return
}

look_right :: proc ( a: f32 ) -> ( res: bool ) {
    res = a >= 90 && a <= 270 ? true : false 
    return
}

look_up :: proc ( a: f32 ) -> ( res: bool ) {
    res = a >= 0 && a <= 180.0 ? true : false  
    return
}


cast_rays :: proc ( player: ^Player ) {

    r : rl.Ray
    incr_angle: f32 
    demi_fov : f32 = player^.fov / 2.0
    lowest_angle : f32 = player^.angle - demi_fov
    hightest_angle : f32 = player^.angle + demi_fov
    step_angle : f32 = math.floor(player.fov / f32(len(player^.rays)))

    remove_range(&player^.rays,0,len(player^.rays))

    for a in lowest_angle ..< hightest_angle {
        cos := math.cos(math.to_radians(a))
        sin := math.sin(math.to_radians(a))
        r.position = {player^.position.x + cos * player^.ray_lenght,player^.position.y + sin * player^.ray_lenght,0}
        r.direction = {cos,sin,0}
        append_elem(&player^.rays,r)
        incr_angle += step_angle 
    }

}


ray_collision :: proc ( player: ^Player ) {

}



update_player :: proc ($COL, $LIG: int, player: ^Player, carte: [COL][LIG]rune ) {

    p : Player = player^ 
    key : rl.KeyboardKey = rl.GetKeyPressed()

    #partial switch key {
        case rl.KeyboardKey.UP:
            player.angle -= player.angle_rotation
            player^.angle = fix_angle(player^.angle)
        case rl.KeyboardKey.DOWN:
            player.angle += player.angle_rotation
            player^.angle = fix_angle(player^.angle)
        case rl.KeyboardKey.LEFT: 
            player^.position.x += math.cos(math.to_radians(player^.angle)) * player^.move_speed
            player^.position.y += math.sin(math.to_radians(player^.angle)) * player^.move_speed
        case rl.KeyboardKey.RIGHT:
            player^.position.x -= math.cos(math.to_radians(player^.angle)) * player^.move_speed
            player^.position.y -= math.sin(math.to_radians(player^.angle)) * player^.move_speed
    }

    player^.x = int(player^.position.x) / TILE_SIZE
    player^.y = int(player^.position.y) / TILE_SIZE

    cast_rays(player)

    if carte[player^.x][player^.y] == '1' {
        player^ = p 
    }

}


draw_carte :: proc ( $COL: int, $LIG: int, carte: [COL][LIG]rune ) {
    color : rl.Color
    for c in 0 ..< COL {
        for l in 0 ..< LIG {
            color = carte[c][l] == '1' ? items[.Wall] : items[.Ground]
            rl.DrawRectangleV({f32(c*TILE_SIZE),f32(l*TILE_SIZE)},{TILE_SIZE-1,TILE_SIZE-1},color)
        }
    }
}


draw_info :: proc ( player : Player ) {
    angle := math.to_radians(player.angle)
    builder : strings.Builder
    builder_radiant : strings.Builder
    strings.builder_init(&builder)
    strings.builder_init(&builder_radiant)
    strings.write_f32(&builder,player.angle,'f')
    strings.write_f32(&builder_radiant,angle,'f')
    rl.DrawText(strings.to_cstring(&builder),500,550,20,rl.WHITE)
    rl.DrawText(strings.to_cstring(&builder_radiant),500,650,20,rl.WHITE)
    strings.builder_destroy(&builder)
    strings.builder_destroy(&builder_radiant)
}


draw_player :: proc ( player: Player) {
    angle := math.to_radians(player.angle) 
    rl.DrawCircleV(player.position,player.circle_size,items[.Player])
    for u in player.rays {
        rl.DrawLineEx({player.position.x,player.position.y},{u.position.x,u.position.y},1,items[.Rayon])
    }
}


main :: proc () {

    player : Player = init_player()

    rl.SetTraceLogLevel(.NONE)

    rl.InitWindow(SCREEN_WIDTH,SCREEN_HEIGHT,TITLE)

    rl.SetConfigFlags({.VSYNC_HINT})
    rl.SetTargetFPS(60)

    carte, success := get_carte("./assets/carte.txt",10,10)

    
    for !rl.WindowShouldClose() {
        update_player(10,10,&player,carte)
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        draw_carte(10,10,carte)
        draw_player(player)
        draw_info(player)
        rl.EndDrawing()
    }
    
    rl.CloseWindow()
    delete_dynamic_array(player.rays)
}