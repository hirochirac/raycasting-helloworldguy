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

Carte :: struct ($COL, $LIG : int, $T: typeid) {
    array: [COL][LIG]T
}


// Carte :: union ($COL, $LIG : int, $T: typeid) {
//     [COL][LIG]T,
// }



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


init_player :: proc ( x : int = 3, y : int =  2,
                     circle_size: f32 = 5.0,
                     angle : f32 = 90.0,
                     angle_rotation : f32 = 120.0,
                     move_speed : f32 = 100.0,
                     ray_lenght : f32 = 200.0, fov: f32 = 60.0, number_of_ray: i32 = 100 ) -> (player: Player) {
    player.x = x
    player.y = y
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
    if ( a < 0 ) {
        angle += 360
    } else if a >= 360 {
        angle -= 360
    }
    return
}

// cast_rays :: proc ( player: ^Player ) {

//     r : rl.Ray
//     incr_angle: f32 
//     demi_fov : f32 = player^.fov / 2.0
//     lowest_angle : f32 = player^.angle - demi_fov
//     hightest_angle : f32 = player^.angle + demi_fov
//     step_angle : f32 = math.floor(player.fov / f32(len(player^.rays)))

//     remove_range(&player^.rays,0,len(player^.rays))

//     for a in lowest_angle ..< hightest_angle {
//         cos := math.cos(math.to_radians(a))
//         sin := math.sin(math.to_radians(a))
//         r.position = {player^.position.x + cos * player^.ray_lenght,player^.position.y + sin * player^.ray_lenght,0}
//         r.direction = {cos,sin,0}
//         append_elem(&player^.rays,r)
//         incr_angle += step_angle 
//     }

// }


cast_a_ray :: proc ( player: Player, carte: [10][10]rune ) -> ( ray: rl.Ray ) {

    v_rayPos, h_rayPos, offset : rl.Vector2
    angle : f32 = math.to_radians_f32(player.angle)
    htan : f32 = - 1 / math.tan(angle)
    //vtan : f32 = -math.tan(angle) 
    sin : f32 = math.sin(angle)
    cos : f32 = math.cos(angle)
    hdist, vdist : f32
    vdof, hdof : f32
 
    if sin > 0.001 {
        // looking down
        h_rayPos.y = math.floor(player.position.y / TILE_SIZE) * TILE_SIZE + TILE_SIZE
        h_rayPos.x = math.floor(player.position.y - h_rayPos.y) * htan + player.position.x
        offset.y = TILE_SIZE
        offset.x = -offset.y * htan
        vdof = 0
    } else if sin < -0.001 {
        // looking up
        h_rayPos.y = math.floor(player.position.y / TILE_SIZE) * TILE_SIZE - 0.01
        h_rayPos.x = math.floor(player.position.y - h_rayPos.y) * htan + player.position.x
        offset.y = -TILE_SIZE
        offset.x = -offset.y * htan
        vdof = 0
    } else {
        vdof = player.ray_lenght
    }

    for ; vdof < player.ray_lenght; {
        mapX := int(h_rayPos.x / TILE_SIZE)
        mapY := int(h_rayPos.y / TILE_SIZE)

        if mapY < len(carte) && mapX < len(carte) && carte[mapX][mapY] == '1' {
            hdist = math.sqrt(math.pow(player.position.x - h_rayPos.x,2) + math.pow(player.position.y - h_rayPos.y,2))
            fmt.printfln("%f %f",mapX,mapY)
            break
        }
        vdof += 1

        h_rayPos += offset
    }

    // if cos > 0.001 {
    //     // looking right
    //     v_rayPos.x = math.floor(player.position.x / TILE_SIZE) * TILE_SIZE
    //     v_rayPos.y = math.floor(player.position.x - v_rayPos.x) * vtan + player.position.y
    //     offset.x = TILE_SIZE
    //     offset.y = -TILE_SIZE * vtan
    // } else if cos < -0.001 {
    //     // looking left
    //     v_rayPos.x = math.floor(player.position.x / TILE_SIZE) * TILE_SIZE + TILE_SIZE - 0.01
    //     v_rayPos.y = math.floor(player.position.x - v_rayPos.x) * vtan + player.position.y
    //     offset.x = -TILE_SIZE
    //     offset.y = -TILE_SIZE * vtan
    // } else {
    //     vdof = player.ray_lenght
    // } 

    // for j in vdof..< player.ray_lenght {
    //     mapX := int(v_rayPos.x / TILE_SIZE)
    //     mapY := int(v_rayPos.y / TILE_SIZE)

    //     fmt.printfln("mapX : %d, mapY : %d",mapX,mapY)

    //     if mapY > 0 && mapY < len(carte) && mapX > 0 && mapX < len(carte[0]) && carte[mapY][mapX] == '1' {
    //         vdist = math.sqrt(math.pow(player.position.x - v_rayPos.x,2) + math.pow(player.position.y - v_rayPos.y,2))
    //         break
    //     }

    //     v_rayPos += offset
        
    // }

    end_pos := h_rayPos
    rl.DrawLineEx({player.position.x,player.position.y},end_pos,1,items[.Rayon])

    return

}

update_player :: proc (player: ^Player, carte: [10][10]rune ) {

    p : Player = player^ 
    key : rune = rl.GetCharPressed()
    


    switch key {
        case 'a':
            player^.angle -= player^.angle_rotation * rl.GetFrameTime()
        case 'd':
            player^.angle += player^.angle_rotation  * rl.GetFrameTime()
        case 'w': 
            player^.position.x += math.cos(math.to_radians(player^.angle)) * rl.GetFrameTime() * player^.move_speed
            player^.position.y += math.sin(math.to_radians(player^.angle)) * rl.GetFrameTime() * player^.move_speed
        case 'c':
            player^.position.x -= math.cos(math.to_radians(player^.angle)) * rl.GetFrameTime() * player^.move_speed
            player^.position.y -= math.sin(math.to_radians(player^.angle)) * rl.GetFrameTime() * player^.move_speed
    }


    player^.x = int(player^.position.x) / TILE_SIZE
    player^.y = int(player^.position.y) / TILE_SIZE

    fmt.printfln("x : %d, y : %d,  %c",player^.x,player^.y,carte[player^.y][player^.x])

    if carte[player^.x][player^.y] == '1' {
        player^ = p 
    }

}


draw_carte :: proc ( carte: [10][10]rune ) {
    color : rl.Color
    for c in 0 ..< 10 {
        for l in 0 ..< 10 {
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


draw_player :: proc ( player: Player, carte: [10][10]rune ) {
    angle := math.to_radians(player.angle) 
    rl.DrawCircleV(player.position,player.circle_size,items[.Player])
    cast_a_ray(player,carte)
    // for u in player.rays {
    //     rl.DrawLineEx({player.position.x,player.position.y},{u.position.x,u.position.y},1,items[.Rayon])
    // }
}


main :: proc () {
 

    player : Player = init_player()

    rl.SetTraceLogLevel(.NONE)

    rl.InitWindow(SCREEN_WIDTH,SCREEN_HEIGHT,TITLE)

    rl.SetConfigFlags({.VSYNC_HINT})
    rl.SetTargetFPS(60)

    carte, success := get_carte("./assets/carte.txt",10,10)

    
    for !rl.WindowShouldClose() {
        update_player(&player,carte)
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        draw_carte(carte)
        draw_player(player,carte)
        draw_info(player)
        rl.EndDrawing()
    }
    
    rl.CloseWindow()
    delete_dynamic_array(player.rays)
    
}