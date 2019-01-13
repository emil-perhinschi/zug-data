module tests.populations;

import std.stdio: writeln;

import zug.matrix;

/**
*  energy: how much energy can be harvested per unit of time
*  population: people living in that map node
*  explored: if the general population knows about it
*/
struct World {
    Matrix!int energy;
    Matrix!(Agent[]) population;
}

/**
* will create a world of size height*width
* will create random energy levels for each cell
* will set the chart to be 
* will pick a cell (top left corner, that is 0,0) to place the initial population
*/
void main() { 
    immutable loops = 100;
    World world = init();
    writeln(world);

    for (int i = 0; i < loops; i++) {

    }
}

World init() {
    immutable int width = 1200;
    immutable int height = 1000;
    immutable int data_length = width * height;

    int min_energy = 0;
    int max_energy = 10_000;
    uint seed = 12_345_678;


    int[data_length] energy_data = random_array!int(data_length, min_energy, max_energy, seed);
    auto energy = Matrix!int(energy_data, width);

    auto population = Matrix!(Agent[])(width, height);
    auto world = World(energy, population);

    Agent[] initial_population = initialize_population(seed);
    world.population.set(0,0, initial_population);

    return world;
}

/**
* age: how old
* initiative: how likely to move away in search of better pastures
* energy: how much energy is stored
* consumption: how much energy is consuming over unit of time
*/
struct Agent {
    int id = 0;
    int age = 0;
    int initiative = 0;
    int sight = 0;
    int energy = 0;
    int consumption = 0;
}

Agent[] initialize_population(uint seed) {
    import std.random : Random, uniform;
    auto rnd = Random(seed);

    int agent_initial_population = 100;
    int agent_initial_energy = 100;
    int agent_min_energy_consumption = 1;
    int agent_min_sight_radius = 3;
    int agent_min_initiative = 0;
    int agent_max_age = 50;

    Agent[] population;
    for (int i = 0; i < agent_initial_population; i++) {
        int age = uniform(0, agent_max_age, rnd);
        int initiative = uniform(0, 100, rnd);
        int sight = uniform(agent_min_sight_radius, agent_min_sight_radius + 5, rnd);
        int consumption = agent_min_energy_consumption + uniform(0, 1, rnd);
        population ~= Agent(i, age, initiative, sight, agent_initial_energy, consumption);
    }
    return population;
}