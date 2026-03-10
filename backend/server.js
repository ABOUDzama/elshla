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

const PORT = process.env.PORT || 3000;

const rooms = {};

function generateRoomCode() {
    return Math.floor(10000 + Math.random() * 90000).toString();
}

io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    // Create a room - host can have avatar
    socket.on('create_room', ({ playerName, avatar }) => {
        let roomCode = generateRoomCode();
        while (rooms[roomCode]) {
            roomCode = generateRoomCode();
        }

        rooms[roomCode] = {
            host: socket.id,
            players: [
                {
                    id: socket.id,
                    name: playerName,
                    avatar: avatar || null,
                    isHost: true
                }
            ],
            game: null
        };

        socket.join(roomCode);
        socket.roomCode = roomCode;
        console.log(`Room ${roomCode} created by ${playerName}`);
        socket.emit('room_created', { roomCode });

        // Send updated player list to all in room
        io.to(roomCode).emit('players_updated', {
            players: rooms[roomCode].players
        });
    });

    // Join a room - guests can have avatars too
    socket.on('join_room', ({ roomCode, playerName, avatar }) => {
        const room = rooms[roomCode];
        if (room) {
            // Check if player already in room (reconnect)
            const existingPlayer = room.players.find(p => p.id === socket.id);
            if (!existingPlayer) {
                room.players.push({
                    id: socket.id,
                    name: playerName,
                    avatar: avatar || null,
                    isHost: false
                });
            }

            socket.join(roomCode);
            socket.roomCode = roomCode;
            console.log(`${playerName} joined room ${roomCode}. Total: ${room.players.length}`);

            // Notify all players in the room
            io.to(roomCode).emit('players_updated', {
                players: room.players
            });

            socket.emit('join_success', { roomCode });
        } else {
            socket.emit('error_message', { message: 'الغرفة غير موجودة.' });
        }
    });

    // Update avatar (can be called after joining)
    socket.on('update_avatar', ({ roomCode, avatar }) => {
        const room = rooms[roomCode];
        if (room) {
            const player = room.players.find(p => p.id === socket.id);
            if (player) {
                player.avatar = avatar;
                io.to(roomCode).emit('players_updated', {
                    players: room.players
                });
            }
        }
    });

    // Host selects a game and starts
    socket.on('select_game', ({ roomCode, gameName }) => {
        const room = rooms[roomCode];
        if (room && room.host === socket.id) {
            room.game = gameName;
            console.log(`Game ${gameName} selected for room ${roomCode}`);
            io.to(roomCode).emit('game_selected', { gameName });
        }
    });

    // Forward general game moves
    socket.on('game_move', ({ roomCode, moveData }) => {
        socket.to(roomCode).emit('game_move', moveData);
    });

    // Ludo specific events
    socket.on('ludo_dice_rolled', ({ roomCode, diceValue }) => {
        socket.to(roomCode).emit('ludo_dice_rolled', { diceValue });
    });

    socket.on('ludo_state_updated', ({ roomCode, moveData }) => {
        socket.to(roomCode).emit('ludo_state_updated', moveData);
    });

    // Gobblet specific events
    socket.on('gobblet_state_updated', ({ roomCode, moveData }) => {
        socket.to(roomCode).emit('gobblet_state_updated', moveData);
    });

    // Seega specific events
    socket.on('seega_state_updated', ({ roomCode, moveData }) => {
        socket.to(roomCode).emit('seega_state_updated', moveData);
    });

    socket.on('reset_game', ({ roomCode }) => {
        io.to(roomCode).emit('reset_game');
    });

    // Handle player returning to room
    socket.on('player_returned', ({ roomCode, playerName }) => {
        io.to(roomCode).emit('player_returned_msg', {
            message: `عاد اللاعب "${playerName}" إلى غرفة الانتظار.`
        });
    });

    // Handle disconnect
    socket.on('disconnect', () => {
        console.log(`User disconnected: ${socket.id}`);
        const roomCode = socket.roomCode;
        if (roomCode && rooms[roomCode]) {
            const room = rooms[roomCode];
            const wasHost = room.host === socket.id;

            // Find the leaving player's name BEFORE removing
            const leavingPlayer = room.players.find(p => p.id === socket.id);
            const leavingName = leavingPlayer ? leavingPlayer.name : 'لاعب';

            // Remove player from list
            room.players = room.players.filter(p => p.id !== socket.id);

            if (room.players.length === 0 || wasHost) {
                // If host left or room is empty, close the room
                io.to(roomCode).emit('room_closed', {
                    message: `👑 غادر المضيف "${leavingName}" الغرفة. انتهت الجلسة.`
                });
                delete rooms[roomCode];
            } else {
                // Notify remaining players with the name
                io.to(roomCode).emit('player_left', {
                    message: `👋 غادر "${leavingName}" الغرفة.`,
                    players: room.players
                });
                io.to(roomCode).emit('players_updated', { players: room.players });
            }
        }
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
