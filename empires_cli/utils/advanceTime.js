async function advanceTime(timeInSeconds) {
    const time = parseInt(timeInSeconds, 10);
    const response = await fetch("http://127.0.0.1:5050/increase_time", {
        headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
        },
        method: "POST",
        body: JSON.stringify({ time: time }),
    });
    const res = await response.json();
    return res;
}

module.exports = { advanceTime };
