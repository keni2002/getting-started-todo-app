const GREETINGS = [
    "eliaberg",
    "i love you",
    "Elizabeth, i miss u"
];

module.exports = async (req, res) => {
    res.send({
        greeting: GREETINGS[ Math.floor(Math.random()* GREETINGS.length)],
    });
};
