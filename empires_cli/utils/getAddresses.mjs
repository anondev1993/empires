export async function getDeployedAddresses() {
    const response = await fetch("http://127.0.0.1:5050/predeployed_accounts", {
        method: "GET",
    });
    const res = await response.json();
    return res;
}
