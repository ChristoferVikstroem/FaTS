require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-vyper");


/** @type import('hardhat/config').HardhatUserConfig */

// a first quoty doty task
task("quote", "Quoty doty", () => {
  quotes = ["To understand recursion, you must first understand recursion. - Unknown",
    "You can't trust code that you did not totally create yourself. - Ken Thompson",
    "There are only two kinds of programming languages: those people always bitch about and those nobody uses.",
    "Most good programmers do programming not because they expect to get paid or get adulation by the public, but because it is fun to program. - Linus Torvalds",
    "In software, the need is constant—the bugs arrive all the time. It's like an apple tree producing apples. You have to keep picking them off the tree. - Bill Gates",
    "Computers are like Old Testament gods; lots of rules and no mercy. - Joseph Campbell",
    "You know you have achieved perfection in design, not when you have nothing more to add, but when you have nothing more to take away.",
    "The first rule of algorithm club is, don't talk about algorithm club. The second rule of algorithm club is, don't talk about algorithm club in parallel. - Gene GPT Amdahl",
    "Like a well-coded program, a wrap combines layers seamlessly. In the world of both code and cuisine, the key is balance – a perfect blend of ingredients and logic. So, savor the wrap, where technology meets taste, and every byte is as delightful as every bite!"]
  console.log(quotes[Math.floor(Math.random() * quotes.length)]);
});


module.exports = {
  vyper: {
    version: "0.3.7"
  },
  solidity: "0.8.19",
};
