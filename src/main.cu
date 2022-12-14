#include "flamegpu/flamegpu.h"

FLAMEGPU_AGENT_FUNCTION(outputMessage, flamegpu::MessageNone, flamegpu::MessageSpatial3D) {
    FLAMEGPU->message_out.setVariable<flamegpu::id_t>("id", FLAMEGPU->getID());
    FLAMEGPU->message_out.setLocation(
        FLAMEGPU->getVariable<float>("x"),
        FLAMEGPU->getVariable<float>("y"),
        FLAMEGPU->getVariable<float>("z"));
    return flamegpu::ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(move, flamegpu::MessageSpatial3D, flamegpu::MessageNone) {
    const flamegpu::id_t ID = FLAMEGPU->getID();
    const float REPULSE_FACTOR = FLAMEGPU->environment.getProperty<float>("repulse");
    const float RADIUS = FLAMEGPU->message_in.radius();
    float fx = 0.0;
    float fy = 0.0;
    float fz = 0.0;
    const float x1 = FLAMEGPU->getVariable<float>("x");
    const float y1 = FLAMEGPU->getVariable<float>("y");
    const float z1 = FLAMEGPU->getVariable<float>("z");
    int count = 0;
    for (const auto &message : FLAMEGPU->message_in(x1, y1, z1)) {
        if (message.getVariable<flamegpu::id_t>("id") != ID) {
            const float x2 = message.getVariable<float>("x");
            const float y2 = message.getVariable<float>("y");
            const float z2 = message.getVariable<float>("z");
            float x21 = x2 - x1;
            float y21 = y2 - y1;
            float z21 = z2 - z1;
            const float separation = sqrtf(x21*x21 + y21*y21 + z21*z21);
            if (separation < RADIUS && separation > 0.0f) {
                float k = sinf((separation / RADIUS)*3.141f*-2)*REPULSE_FACTOR;
                // Normalise without recalculating separation
                x21 /= separation;
                y21 /= separation;
                z21 /= separation;
                fx += k * x21;
                fy += k * y21;
                fz += k * z21;
                count++;
            }
        }
    }
    fx /= count > 0 ? count : 1;
    fy /= count > 0 ? count : 1;
    fz /= count > 0 ? count : 1;
    FLAMEGPU->setVariable<float>("x", x1 + fx);
    FLAMEGPU->setVariable<float>("y", y1 + fy);
    FLAMEGPU->setVariable<float>("z", z1 + fz);
    FLAMEGPU->setVariable<float>("drift", sqrtf(fx*fx + fy*fy + fz*fz));
    return flamegpu::ALIVE;
}
FLAMEGPU_STEP_FUNCTION(Validation) {
    static float prevTotalDrift = FLT_MAX;
    static unsigned int driftDropped = 0;
    static unsigned int driftIncreased = 0;
    // This value should decline? as the model moves towards a steady equlibrium state
    // Once an equilibrium state is reached, it is likely to oscillate between 2-4? values
    float totalDrift = FLAMEGPU->agent("Circle").sum<float>("drift");
    if (totalDrift <= prevTotalDrift)
        driftDropped++;
    else
        driftIncreased++;
    prevTotalDrift = totalDrift;
    // printf("Avg Drift: %g\n", totalDrift / FLAMEGPU->agent("Circle").count());
    printf("%.2f%% Drift correct\n", 100 * driftDropped / static_cast<float>(driftDropped + driftIncreased));
}
int main(int argc, const char ** argv) {
    flamegpu::ModelDescription model("template");

    const unsigned int AGENT_COUNT = 16384;
    const float ENV_MAX = static_cast<float>(floor(cbrt(AGENT_COUNT)));
    const float RADIUS = 2.0f;

    // global environment variables
    flamegpu::EnvironmentDescription env = model.Environment();
    env.newProperty("repulse", 0.05f);

    // Location message
    flamegpu::MessageSpatial3D::Description message = model.newMessage<flamegpu::MessageSpatial3D>("location");
    message.newVariable<flamegpu::id_t>("id");
    message.setRadius(RADIUS);
    message.setMin(0, 0, 0);
    message.setMax(ENV_MAX, ENV_MAX, ENV_MAX);
    
    // Circle agent
    flamegpu::AgentDescription  agent = model.newAgent("Circle");
    agent.newVariable<float>("x");
    agent.newVariable<float>("y");
    agent.newVariable<float>("z");
    agent.newVariable<float>("drift");  // Store the distance moved here, for validation
    
    // Define each function. 
    flamegpu::AgentFunctionDescription outputMessageDescription = agent.newFunction("outputMessage", outputMessage);
    outputMessageDescription.setMessageOutput("location");
    flamegpu::AgentFunctionDescription moveDescription = agent.newFunction("move", move);
    moveDescription.setMessageInput("location");
    // Add a dependency that move requires outputMessage to have executed
    moveDescription.dependsOn(outputMessageDescription);

    // Identify the root of execution
    model.addExecutionRoot(outputMessageDescription);
    
    // Add a step function which in this case is used as a crude form of validation
    model.addStepFunction(Validation);

    // Build the exeuction graph
    model.generateLayers();

    // Create the simulation
    flamegpu::CUDASimulation simulation(model, argc, argv);

    // Create visualisation if enabled
#ifdef FLAMEGPU_VISUALISATION
    flamegpu::visualiser::ModelVis visualiser = simulation.getVisualisation();
    {
        const float INIT_CAM = ENV_MAX * 1.25F;
        visualiser.setInitialCameraLocation(INIT_CAM, INIT_CAM, INIT_CAM);
        visualiser.setCameraSpeed(0.01f);
        auto cirlceAgentVisualiser = visualiser.addAgent("Circle");
        // Position vars are named x, y, z; so they are used by default
        cirlceAgentVisualiser.setModel(flamegpu::visualiser::Stock::Models::ICOSPHERE);
        cirlceAgentVisualiser.setModelScale(1/10.0f);
        // Render the Subdivision of spatial messaging
        {
            const float ENV_MIN = 0;
            const int DIM = static_cast<int>(ceil((ENV_MAX - ENV_MIN) / RADIUS));  // Spatial partitioning scales up to fit none exact environments
            const float DIM_MAX = DIM * RADIUS;
            auto pen = visualiser.newLineSketch(1, 1, 1, 0.2f);  // white
            // X lines
            for (int y = 0; y <= DIM; y++) {
                for (int z = 0; z <= DIM; z++) {
                    pen.addVertex(ENV_MIN, y * RADIUS, z * RADIUS);
                    pen.addVertex(DIM_MAX, y * RADIUS, z * RADIUS);
                }
            }
            // Y axis
            for (int x = 0; x <= DIM; x++) {
                for (int z = 0; z <= DIM; z++) {
                    pen.addVertex(x * RADIUS, ENV_MIN, z * RADIUS);
                    pen.addVertex(x * RADIUS, DIM_MAX, z * RADIUS);
                }
            }
            // Z axis
            for (int x = 0; x <= DIM; x++) {
                for (int y = 0; y <= DIM; y++) {
                    pen.addVertex(x * RADIUS, y * RADIUS, ENV_MIN);
                    pen.addVertex(x * RADIUS, y * RADIUS, DIM_MAX);
                }
            }
        }
    }
    visualiser.activate();
#endif
    
    // initialise a population of agents if not provided on disk
    if (simulation.getSimulationConfig().input_file.empty()) {
        // Currently population has not been init, so generate an agent population on the fly
        std::mt19937_64 rng;
        std::uniform_real_distribution<float> dist(0.0f, ENV_MAX);
        flamegpu::AgentVector population(model.Agent("Circle"), AGENT_COUNT);
        for (unsigned int i = 0; i < AGENT_COUNT; i++) {
            flamegpu::AgentVector::Agent instance = population[i];
            instance.setVariable<float>("x", dist(rng));
            instance.setVariable<float>("y", dist(rng));
            instance.setVariable<float>("z", dist(rng));
        }
        simulation.setPopulationData(population);
    }

    // Execute the simulation
    simulation.simulate();

#ifdef FLAMEGPU_VISUALISATION
    visualiser.join();
#endif

    // Ensure profiling / memcheck work correctly
    flamegpu::util::cleanup();

    return EXIT_SUCCESS;
}
