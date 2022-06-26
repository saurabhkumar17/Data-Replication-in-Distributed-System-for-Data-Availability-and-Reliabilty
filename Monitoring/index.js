// const a1 = new WebSocket("ws://localhost:9001");


const websockets = [
    new WebSocket("ws://localhost:9101"),
    new WebSocket("ws://localhost:9102"),
    new WebSocket("ws://localhost:9103"),
    new WebSocket("ws://localhost:9111"),
    new WebSocket("ws://localhost:9112"),
    new WebSocket("ws://localhost:9121"),
    new WebSocket("ws://localhost:9122"),
]

// let a1_cl_data = new Map()
// let a2_cl_data = new Map()
// let a3_cl_data = new Map()
// let b1_l1_data = new Map()
// let b2_l1_data = new Map()
// let c1_l2_data = new Map()
// let c2_l2_data = new Map()

let data = [new Map(), new Map(),new Map(), new Map(), new Map(), new Map(), new Map()]
const serverIDs = ["a1", "a2", "a3", "b1", "b2", "c1", "c2"]

websockets.forEach((server, index) => {
        server.onopen = function (event){
            server.send("Client Connecting to ");
        }

        server.onmessage = function (event){
            // console.log(event.data)
            data[index] = JSON.parse(event.data)

            document.getElementById(serverIDs[index]).innerText = event.data
        }
    }
)

// a1.onopen = function (event) {
//     a1.send("Client Connecting to ");
// };
//
// a1.onmessage = function (event) {
//     console.log(event.data);
// }

