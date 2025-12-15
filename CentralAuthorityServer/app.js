const express = require('express');
const mariadb = require('mariadb');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// Load .env data
require('dotenv').config();

// Init Logging
let logDir = path.resolve(__dirname, '../logs');
fs.mkdirSync(logDir, { recursive: true });

const app = express();
const PORT = 3000;

app.use(express.static('public'));
app.use(express.json());

const EnvSecret = process.env.CASINO_SECRET;

// Database configuration
const dbConfig = {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    connectionLimit: process.env.DB_CONNECTION_LIMIT || 10,
    supportBigNumbers: true, // Needed as otherwise will error out when trying to parse it as a number
    bigNumberStrings: true // Needed as otherwise will error out when trying to parse it as a number
};

// Create connection pool to database
const pool = mariadb.createPool(dbConfig);

// Test database connection
async function TestDatabaseConnection() {
    let conn;
    try {
        conn = await pool.getConnection();
        console.log('Connected to MariaDB! 🦭');
    } catch (error) {
        console.error('Database connection failed:', error);
        if (conn) conn.release();
        //process.exit(1);
    } finally {
        if (conn) conn.release();
    }
}

function logAction(actionObject)
{
    if (actionObject === undefined || actionObject === null)
    {
        return;
    }

    const entry = JSON.stringify({ ...actionObject, timestamp: Date.now() }) + '\n';

    // Get day in unix time
    const now = new Date();
    now.setHours(0,0,0,0); // Set time to midnight
    const dayTs = Math.floor(now.getTime() / 1000);

    // Get file
    const logFile = path.join(logDir, `${dayTs}.jsonl`)
    const fileInterface = fs.openSync(logFile, 'a');
    try{
        fs.writeSync(fileInterface, entry);
        fs.fsyncSync(fileInterface); // ensure crash-safe flush
    } finally {
        fs.closeSync(fileInterface);
    }

    console.log(`logged: ${dayTs}:${actionObject}`);
}

function generateUserId(){
    // Generate a unique number
    const Time = Number(Date.now());
    const Random = crypto.randomInt(2147483647);

    const NewUserId = Time + Random;
    console.log(`Generated new user id: ${NewUserId}`)
    return NewUserId;
}

function isValidSecret(Secret, UserId, AmountRequested)
{
    if (!Secret || !UserId || !AmountRequested)
    {
        return false;
    }

    console.log(UserId);
    console.log(Secret);
    const dollarIndex = Secret.toString().indexOf('$');
    const colonIndex = Secret.toString().indexOf(':');
    const KeyIndex = Number(Secret.toString().substring(dollarIndex + 1, colonIndex));
    const KeyValue = parseInt(UserId.toString()[KeyIndex]);
    console.log(KeyIndex);
    console.log(KeyValue);
    const stripped = Secret.substring(colonIndex + 1)
    const Key = Math.min(Math.max(KeyValue, 3), 9);
    console.log(Key);
    console.log(stripped);

    let DecodedSecret = "";
    console.log(Key)
    for (let Index = 0; Index < stripped.length; Index++) {
        if (Index % Key == 0)
            DecodedSecret += stripped[Index];
    }
    console.log(DecodedSecret);

    let DecryptedSecret = "";
    let Count = 0;
    Count = 0;
    for (let decodeIndex = 0; decodeIndex < DecodedSecret.length; decodeIndex++) {
        const Element = DecodedSecret.charCodeAt(decodeIndex);
        const KeyElement = UserId.toString().charCodeAt(Count);
        DecryptedSecret += String.fromCharCode(Element ^ KeyElement);
        Count++;
        if (Count >= UserId.toString().length)
        {
            Count = 0;
        }
    }
    console.log(DecryptedSecret);
    console.log(DecryptedSecret === (EnvSecret + AmountRequested));
    return (DecryptedSecret === (EnvSecret + AmountRequested));
}

function HideMessage(AmountRequested, UserId)
{
    // Encrypt
    let EncryptedSecret = "";
    let Secret = EnvSecret + AmountRequested;
    let Count = 0;
    for (let encryptIndex = 0; encryptIndex < Secret.length; encryptIndex++) {
        const Element = Secret.charCodeAt(encryptIndex);
        const KeyElement = UserId.toString().charCodeAt(Count);
        EncryptedSecret += String.fromCharCode(Element ^ KeyElement);

        Count++;
        if (Count >= UserId.toString().length)
        {
            Count = 0;
        }
    }
    console.log(Secret)
    console.log(EncryptedSecret);

    // Junk data gen
    let ResultString = "";
    const JunkUserIndex = Math.floor(Math.random() * UserId.toString().length);
    console.log(UserId);
    console.log(JunkUserIndex);
    let JunkKey = Number(UserId.toString()[JunkUserIndex])
    JunkKey = Math.min(Math.max(JunkKey, 3), 9);
    console.log(JunkKey);
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    let EncryptedIndex = 0;
    for (let JunkIndex = 0; EncryptedIndex < EncryptedSecret.length; JunkIndex++) {
        if (JunkIndex % JunkKey === 0) {
            ResultString += EncryptedSecret[EncryptedIndex];
            EncryptedIndex += 1;
        }
        else{
            const randomChar = chars[Math.floor(Math.random() * chars.length)];
            ResultString += randomChar.toString();
        }
    }

    ResultString = `\$${JunkUserIndex}:${ResultString}`;

    console.log(ResultString);
    return ResultString;
}

// API Routing
app.get('/', (req, res) => {
   res.json({ message: "The server glows with power. It sees you. 👀" });
});

app.get('/search/:musicId', (req, res) => {
    // Search through all dirs for the file,
    // once we find it return the public path for wget and the sample rate which is the sub folder
    const files = fs.readdirSync("./public/music/", {recursive: true});
    const searchTerm = req.params.musicId;

    const result = files.filter(file => {
        const afterSlash = file.split('/')[1]; // undefined if no '/'
        if (afterSlash?.includes(searchTerm))
        {
            return file;
        }
    });

    if (result !== undefined && result.length > 0)
    {
        const [sampleRate, filename] = result[0].split('/');
        return res.status(200).json({
            "path" : `music/${result[0]}`,
            "sample-rate" : sampleRate
        });
    }

    return res.status(401).json({error: `File not found`});
})

// Get data of user
app.get('/user/:id', async (req, res) => {
    console.log("/user/:id pinged");
    const userId = req.params.id;
    if (!userId || isNaN(userId)) {
        return res.status(400).json({error: "userId must be valid"});
    }

    // TODO: Lookup user in db and return money amount
    let conn;
    try
    {
        conn = await pool.getConnection();
        const rows = await conn.query('SELECT * FROM users WHERE UserId = ? LIMIT 1', userId);
        res.status(200).json(rows[0]);
        console.log(`User ${userId} found! ${rows[0]}`);
    }
    catch (err) {
        res.status(500).json({error: `Failed to get user info: ${err.message}`});
    }
    finally {
        if (conn) conn.release();
    }
});

//Register new user
app.post('/register', async (req, res) => {
    const NewUserId = generateUserId();

    console.log("/register pinged");

    const { name } = req.body;
    if (name === undefined) {
        return res.status(401).json({error: "name must be valid"});
    }

    // Add new user to db
    let conn;
    try
    {
        conn = await pool.getConnection();
        await conn.query('INSERT INTO users (UserId, Name) VALUES (?, ?)', [NewUserId, name]);
        logAction({"message" : "NewUserRegistered", "userId" : NewUserId, "username" : name});
        console.log(`Created new user: ${NewUserId}!`)
    }catch(err){
        res.status(500).json({error: `Failed to register new user: ${err.message}`});
    }finally{
        res.status(200).json({userId: NewUserId});
        if (conn) await conn.release();
    }
});

app.post('/vault', async (req, res) => {
    console.log("/vault");
    const { items } = req.body;
    console.log(items);
    // Validate input
    if (!items || !Array.isArray(items)) {
        return res.status(400).json({ error: "items must be a valid array" });
    }

    // Transform items if needed (here we just log name and count)
    const formattedItems = items.map(i => ({
        name: i.name,
        amount: i.amount
    }));

    // Invoke your logger
    logAction({
        message: "VaultSync",
        vaultChunk: formattedItems
    });

    return res.status(200).json({message: "Updated vault info!"});
});

app.post('/atm', async (req, res) => {
    const { deposits, withdrawals } = req.body;
    if (deposits === undefined || deposits === null || withdrawals === undefined || withdrawals === null) {
        return res.status(401).json({error: "deposits and withdrawals must be valid arrays"});
    }

    logAction({"message": "VaultUpdate", "deposits": deposits, "withdrawals": withdrawals});
});

// Set new currency amount diff
app.post('/update', async (req, res) => {
    const { userId, amount, secret } = req.body;
    console.log("/user pinged");
    if (!userId || isNaN(userId)) {
        return res.status(400).json({error: "userId must be valid"});
    }

    if (!amount || isNaN(amount)) {
        return res.status(400).json({error: "amount must be valid"});
    }

    // check
    if (!secret || !isValidSecret(secret, userId, amount))
    {
        return res.status(400).json({error: "Unknown Error"});
    }

    // Add money to new user
    let conn;
    try
    {
        conn = await pool.getConnection();
        const currentValueRows = await conn.query('SELECT Currency FROM users WHERE UserId = ? LIMIT 1', [userId]);
        if (currentValueRows.length === 0) {
            return res.status(401).json({error: `User ${userId} not found`});
        }
        const currencyValue = Number(currentValueRows[0].Currency);
        if (isNaN(currencyValue)) {
            return res.status(401).json({error: "currencyValue must be valid"});
        }

        const newCurrencyValue = currencyValue + amount;
        await conn.query('UPDATE users SET Currency = ? WHERE UserId = ? LIMIT 1', [newCurrencyValue, userId]);

        logAction({"message" : "UserCurrencyUpdated", "userId" : userId, "currency" : newCurrencyValue});
        res.status(200).json({message: "Updated user info"});
    }
    catch (err){
        console.log(err.message);
        res.status(500).json({error: `Failed to effect user currency: ${err.message}!`});
        // Append failure to update currency value of user as this can easily lead to lost winnings/losses/withdrawals/deposits
        fs.appendFile(path.join(__dirname, 'casino.log'),
    `Failed to update currency by < ${amount} > amount for user: ${userId}`, (err) => {
                if (err) console.log(err);
        });
    }finally{
        if (conn) await conn.release();
    }
});

// TODO: Get Currency To Item Ratios

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('Shutting down gracefully...');
    await pool.end();
    process.exit(0);
});

// Start server
TestDatabaseConnection();
app.listen(PORT, () => {
    logAction({"general" : "Started new session"})
    console.log(`Server is running on port ${PORT}`);

    // Print BG3 Reference :3
    console.log("As the server glows, power courses through you.");
    console.log("🔑🪙🔑 AUTHORITY 🔑🪙🔑");
});