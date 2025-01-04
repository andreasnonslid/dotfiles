function helloWorld(name) {
    if (!name) {
        console.log("Hello, World!");
    } else {
        console.log(`Hello, ${name}!`);
    }
}

const sum = (a, b) => {
    return a + b;
};

const result = sum(5, 10);
console.log(result);

helloWorld("ChatGPT");
helloWorld();
