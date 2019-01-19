import vibe.vibe;
import vibe.http.log;
import mustache;

import zug.matrix;

alias Mustache = MustacheEngine!(string);

void main()
{
    auto settings = new HTTPServerSettings;
    settings.port = 8088;
    settings.bindAddresses = ["::1", "127.0.0.1"];
	// see vibe.d/http/vibe/http/server.d for options
	//final class HTTPServerSettings {
	settings.accessLogToConsole = true;

	auto router = new URLRouter;
	
	router.get("/", serveStaticFile("./static/public/html/index.html"));
	// router.get("/css/*", serveStaticFiles("./static/public/"));
	// router.get("/img/*", serveStaticFiles("./static/public/"));
    // router.get("/js/*", serveStaticFiles("./static/public/"));

/*	router.any(
		"*",
		performBasicAuth(
			"The Note app",
			toDelegate(&checkPassword)
		)
	);
*/
	
	router.get("/map_data", &map_data);

    listenHTTP(settings, router);

    logInfo("Please open http://127.0.0.1:" ~ to!string(settings.port) ~ "/ in your browser.");
    runApplication();
}

void map_data(HTTPServerRequest req, HTTPServerResponse res) {
    auto data = random_array!int(16, 0, 15,12_341_234);
    auto orig = Matrix!int(data, 4);
    auto scaled = orig.stretch_bilinear(10,10);
    auto result = scaled.to_2d_array();
    res.writeBody(serializeToJson(result).toString);
}


/**
* will create a world of size height*width
* will create random energy levels for each cell
* will set the chart to be 
* will pick a cell (top left corner, that is 0,0) to place the initial population
*/
void app() { 
    immutable loops = 100;
    World world = init();

    for (int i = 0; i < loops; i++) {
        world.tick();
    }
}


/**
*  energy: how much energy can be harvested per unit of time
*  population: people living in that map node
*  explored: if the general population knows about it
*/
struct World {
    Matrix!int energy;
    Matrix!(Agent[]) population;
}

void tick(World world) 
{   
    // TODO: this should depend on the cell type
    immutable energy_production = 1000;
    world.energy.add(1000);

    for (size_t i = 0; i < world.population.data_length; i++) {
        // for each cell
        //   - agents harvest; if not enough then split proportionally to the harvesting rate of each
        //   - agents consume
        //   - agents whose energy fell below 0 die
        //   - agents move to nearby cells based on initiative, sight, target cell population and some random number
        //   - if energy in the cell falls below a threshold half of the remaining agents are picket at random and move to nearby cells based on initiative
    }
}

World init() {
    immutable int width = 120;
    immutable int height = 100;
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
    int harvesting_rate = 1000;
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