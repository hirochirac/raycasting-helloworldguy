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
    rays: []rl.Ray,
}


init_player :: proc ( x : int = 2, y : int =  2, circle_size: f32 = 5.0, angle : f32 = 90.0, angle_rotation : f32 = 5.0, move_speed : f32 = 10.0, ray_lenght : f32 = 100.0 ) -> (player: Player) {

    player.x = x
    player.x = y
    player.circle_size = circle_size
    player.position.x = f32(x * TILE_SIZE)
    player.position.y = f32(y * TILE_SIZE)
    player.angle = angle
    player.angle_rotation = angle_rotation
    player.move_speed = move_speed
    player.ray_lenght = ray_lenght
    
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


fix_angle :: proc () -> ( angle: f32 ) {
    return
}

look_right :: proc () -> ( res: bool ) {
    return
}

look_up :: proc () -> ( res: bool ) {
    return
}


update_player :: proc ($COL, $LIG: int, player: ^Player, carte: [COL][LIG]rune ) {

    p : Player = player^ 
    key : rl.KeyboardKey = rl.GetKeyPressed()

    #partial switch key {
        case rl.KeyboardKey.UP: player.angle -= player.angle_rotation
        case rl.KeyboardKey.DOWN: player.angle += player.angle_rotation
        case rl.KeyboardKey.LEFT:
            player^.position.x += math.cos(math.to_radians(player^.angle)) * player^.move_speed
            player^.position.y += math.sin(math.to_radians(player^.angle)) * player^.move_speed
        case rl.KeyboardKey.RIGHT:
            player^.position.x -= math.cos(math.to_radians(player^.angle)) * player^.move_speed
            player^.position.y -= math.sin(math.to_radians(player^.angle)) * player^.move_speed
    }

    player^.x = int(player^.position.x) / TILE_SIZE
    player^.y = int(player^.position.y) / TILE_SIZE

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


draw_player :: proc ( player: Player) {
    angle := math.to_radians(player.angle)
    x_end := player.position.x + math.cos(angle) * player.ray_lenght
    y_end := player.position.y + math.sin(angle) * player.ray_lenght
    rl.DrawCircleV(player.position,player.circle_size,items[.Player])
    rl.DrawLineEx({player.position.x,player.position.y},{x_end,y_end},1,items[.Rayon])
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
        rl.EndDrawing()
    }
    
    rl.CloseWindow()
}