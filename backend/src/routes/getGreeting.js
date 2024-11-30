const GREETINGS = [
   "Hello",
   "Hi",
   "May your days be..",

];

module.exports = async (req, res) => {
    res.send({
        greeting: GREETINGS[ Math.floor(Math.random()* GREETINGS.length)],
    });
};
