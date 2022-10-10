async function advanceTime(timeInSeconds) {
    const response = await fetch("http://127.0.0.1:5050/increase_time", {
        method: "POST",
        body: {
            time: timeInSeconds,
        },
    });
    const res = await response.json();
    return res;
}

module.exports = { advanceTime };
