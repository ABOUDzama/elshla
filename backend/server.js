const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());

const server = http.createServer(app);

const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

const PORT = 3000;

const rooms = {};

function generateRoomCode() {
    return Math.floor(10000 + Math.random() * 90000).toString(); // 5 digits
}

io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    socket.on('create_room', ({ playerName }) => {
        let roomCode = generateRoomCode();
        while (rooms[roomCode]) {
            roomCode = generateRoomCode();
        }

        rooms[roomCode] = {
            host: socket.id,
            hostName: playerName,
            guest: null,
            guestName: null,
            game: null
        };

        socket.join(roomCode);
        console.log(`Room ${roomCode} created by ${playerName}`);
        socket.emit('room_created', { roomCode });
    });

    socket.on('join_room', ({ roomCode, playerName }) => {
        const room = rooms[roomCode];
        if (room) {
            if (room.guest === null) {
                room.guest = socket.id;
                room.guestName = playerName;
                socket.join(roomCode);
                console.log(`${playerName} joined room ${roomCode}`);

                io.to(roomCode).emit('player_joined', {
                    hostName: room.hostName,
                    guestName: room.guestName
                });
            } else {
                socket.emit('error_message', { message: 'الغرفة ممتلئة.' });
            }
        } else {
            socket.emit('error_message', { message: 'الغرفة غير موجودة.' });
        }
    });

    socket.on('select_game', ({ roomCode, gameName }) => {
        const room = rooms[roomCode];
        if (room && room.host === socket.id) {
            room.game = gameName;
            console.log(`Game ${gameName} selected for room ${roomCode}`);
            io.to(roomCode).emit('game_selected', { gameName });
        }
    });

    socket.on('game_move', ({ roomCode, moveData }) => {
        socket.to(roomCode).emit('game_move', moveData);
    });

    socket.on('reset_game', ({ roomCode }) => {
        io.to(roomCode).emit('reset_game');
    });

    socket.on('disconnect', () => {
        console.log(`User disconnected: ${socket.id}`);
        for (const roomCode in rooms) {
            const room = rooms[roomCode];
            if (room.host === socket.id || room.guest === socket.id) {
                console.log(`Player left room ${roomCode}`);
                io.to(roomCode).emit('player_left', { message: 'لقد غادر اللاعب الآخر اللعبة.' });
                delete rooms[roomCode];
                break;
            }
        }
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
