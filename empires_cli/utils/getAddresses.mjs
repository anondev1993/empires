export async function getDeployedAddresses() {
  const response = await fetch("http://localhost:5050/predeployed_accounts", {
    method: "GET",
  });
  const res = await response.json();
  return res;
}
