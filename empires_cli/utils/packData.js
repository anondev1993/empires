function packData(realm_data) {
    let data = BigInt(0);

    let regions = realm_data.region;
    let cities = realm_data.cities;
    let harbours = realm_data.harbours;
    let rivers = realm_data.rivers;
    data +=
        BigInt(regions) +
        BigInt(cities) * BigInt(2 ** 8) +
        BigInt(harbours) * BigInt(2 ** 16) +
        BigInt(rivers) * BigInt(2 ** 24);

    let resource_number = realm_data.resource_number;
    let resource_1 = realm_data.resource_1;
    let resource_2 = realm_data.resource_2;
    let resource_3 = realm_data.resource_3;
    let resource_4 = realm_data.resource_4;
    let resource_5 = realm_data.resource_5;
    let resource_6 = realm_data.resource_6;
    let resource_7 = realm_data.resource_7;
    data +=
        BigInt(resource_number) * BigInt(2 ** 32) +
        BigInt(resource_1) * BigInt(2 ** 40) +
        BigInt(resource_2) * BigInt(2 ** 48) +
        BigInt(resource_3) * BigInt(2 ** 48) * BigInt(2 ** 8) +
        BigInt(resource_4) * BigInt(2 ** 48) * BigInt(2 ** 16) +
        BigInt(resource_5) * BigInt(2 ** 48) * BigInt(2 ** 24) +
        BigInt(resource_6) * BigInt(2 ** 48) * BigInt(2 ** 32) +
        BigInt(resource_7) * BigInt(2 ** 48) * BigInt(2 ** 40);

    let wonder = realm_data.wonder;
    let order = realm_data.order;
    return (
        data +
        BigInt(wonder) * BigInt(2 ** 48) * BigInt(2 ** 48) +
        BigInt(order) * BigInt(2 ** 48) * BigInt(2 ** 48) * BigInt(2 ** 8)
    );
}

module.exports = { packData };
