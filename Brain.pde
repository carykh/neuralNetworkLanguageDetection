class Brain {
    double[][]      neurons;
    double[][][]    axons;
    int[]           BRAIN_LAYER_SIZES;
    int             MAX_HEIGHT          = 0;
    boolean         condenseLayerOne    = true;
    int             drawWidth           = 5;
    double          alpha               = 0.1;
    double          confidence          = 0.0;
    int             INPUTS_PER_CHAR;
    String[]        languages;
    int             topOutput           = 0;

    Brain(int[] bls, int ipc, String lang[]) {
        INPUTS_PER_CHAR     = ipc;
        BRAIN_LAYER_SIZES   = bls;
        languages           = lang;
        neurons             = new double[BRAIN_LAYER_SIZES.length][];
        axons               = new double[BRAIN_LAYER_SIZES.length - 1][][];

        for( int x = 0; x < BRAIN_LAYER_SIZES.length; x++) {
            if (BRAIN_LAYER_SIZES[x] > MAX_HEIGHT) { MAX_HEIGHT = BRAIN_LAYER_SIZES[x]; }

            neurons[x] = new double[BRAIN_LAYER_SIZES[x]];

            for (int y = 0; y < BRAIN_LAYER_SIZES[x]; y++) {
                if (y == BRAIN_LAYER_SIZES[x] - 1) { neurons[x][y] = 1; }
                else { neurons[x][y] = 0; }
            }

            if (x < BRAIN_LAYER_SIZES.length - 1) {
                axons[x] = new double[BRAIN_LAYER_SIZES[x]][];

                for (int y = 0; y < BRAIN_LAYER_SIZES[x]; y++) {
                    axons[x][y] = new double[BRAIN_LAYER_SIZES[x + 1] - 1];

                    for(int z = 0; z < BRAIN_LAYER_SIZES[x + 1] - 1; z++){
                        double startingWeight = (Math.random() * 2 - 1) * STARTING_AXON_VARIABILITY;
                        axons[x][y][z] = startingWeight;
                    }
                }
            }
        }
    }

    public double useBrainGetError(double[] inputs, double desiredOutputs[], boolean mutate){
        int[] nonzero = {BRAIN_LAYER_SIZES[0] - 1};

        for (int i = 0; i < BRAIN_LAYER_SIZES[0]; i++) {
            neurons[0][i] = inputs[i];
            if (inputs[i] != 0) { nonzero = append(nonzero, i); }
        }

        for (int x = 0; x < BRAIN_LAYER_SIZES.length; x++) { neurons[x][BRAIN_LAYER_SIZES[x] - 1] = 1.0; }

        for (int x = 1; x < BRAIN_LAYER_SIZES.length; x++) {
            for (int y = 0; y < BRAIN_LAYER_SIZES[x] - 1; y++) {
                float total = 0;
                if (x == 1) { for(int i = 0; i < nonzero.length; i++)                           { total += neurons[x-1][nonzero[i]] * axons[x - 1][nonzero[i]][y]; } }
                else        { for(int input = 0; input < BRAIN_LAYER_SIZES[x - 1] - 1; input++) { total += neurons[x-1][input]      * axons[x - 1][input][y]; } }
                neurons[x][y] = sigmoid(total);
            }
        }

        if (mutate) {
            for (int y = 0; y < nonzero.length; y++) {
                for (int z = 0; z < BRAIN_LAYER_SIZES[1] - 1; z++) {
                    double delta = 0;
                    for (int n = 0; n < BRAIN_LAYER_SIZES[2] - 1; n++) {
                        delta += 2 * (neurons[2][n] - desiredOutputs[n]) * neurons[2][n] * (1 - neurons[2][n]) * axons[1][z][n] * neurons[1][z] * (1 - neurons[1][z]) * neurons[0][nonzero[y]] * alpha;
                    }
                    axons[0][nonzero[y]][z] -= delta;
                }
            }

            for (int y = 0; y < BRAIN_LAYER_SIZES[1]; y++) {
                for (int z = 0; z < BRAIN_LAYER_SIZES[2]-1; z++) {
                    double delta = 2 * (neurons[2][z] - desiredOutputs[z]) * neurons[2][z] * (1 - neurons[2][z]) * neurons[1][y] * alpha;
                    axons[1][y][z] -= delta;
                }
            }
        }

        topOutput = getTopOutput();
        double totalError = 0;
        int end = BRAIN_LAYER_SIZES.length - 1;

        for (int i = 0; i < BRAIN_LAYER_SIZES[end] - 1; i++) { totalError += Math.pow(neurons[end][i] - desiredOutputs[i], 2); }
        return totalError / (BRAIN_LAYER_SIZES[end] - 1);
    }

    public double sigmoid(double input) { return 1.0 / (1.0 + Math.pow(2.71828182846, -input)); }

    public int getTopOutput() {
        double record = -1;
        int recordHolder = -1;
        int end = BRAIN_LAYER_SIZES.length-1;
        for (int i = 0; i < BRAIN_LAYER_SIZES[end] - 1; i++){
            if (neurons[end][i] > record) {
                record = neurons[end][i];
                recordHolder = i;
            }
        }
        confidence = record;
        return recordHolder;
    }

    public void drawBrain(float scaleUp) {
        final float neuronSize = 0.4;
        noStroke();
        fill(128);
        rect(-0.5 * scaleUp, -0.5 * scaleUp, (BRAIN_LAYER_SIZES.length * drawWidth - 1) * scaleUp, MAX_HEIGHT * scaleUp);
        ellipseMode(RADIUS);
        strokeWeight(3);
        textAlign(CENTER);
        textFont(font, 0.53 * scaleUp);

        for (int x = 0; x < BRAIN_LAYER_SIZES.length - 1; x++) {
            for (int y = 0; y < BRAIN_LAYER_SIZES[x]; y++) {
                for(int z = 0; z < BRAIN_LAYER_SIZES[x+1] - 1; z++){
                    drawAxon(x, y, x + 1, z, scaleUp);
                }
            }
        }

        int startPosition = 0;
        if (condenseLayerOne) {
            for (int y = 0; y < BRAIN_LAYER_SIZES[0]; y++){
                if (neurons[0][y] >= 0.5){
                    noStroke();
                    int ay = apY(0, y);
                    //double val = neurons[0][y]; // not used?
                    fill(255);
                    ellipse(0,ay * scaleUp, neuronSize * scaleUp, neuronSize * scaleUp);
                    fill(0);
                    char c = '-';
                    if (ay == BRAIN_LAYER_SIZES[0] / INPUTS_PER_CHAR) { c = '1'; }
                    else if (y % INPUTS_PER_CHAR >= 1) { c = (char)(y % INPUTS_PER_CHAR + 64); }
                    text(c, 0,( ay + (neuronSize * 0.55)) * scaleUp);
                }
            }
            startPosition = 1;
        }
        for (int x = startPosition; x < BRAIN_LAYER_SIZES.length; x++) {
            for (int y = 0; y < BRAIN_LAYER_SIZES[x]; y++) {
                noStroke();
                double val = neurons[x][y];
                fill(neuronFillColor(val));
                ellipse(x * drawWidth * scaleUp, apY(x, y) * scaleUp, neuronSize * scaleUp, neuronSize * scaleUp);
                fill(neuronTextColor(val));
                text(coolify(val), x * drawWidth * scaleUp, (apY(x, y) + (neuronSize * 0.52)) * scaleUp);
                if (x == BRAIN_LAYER_SIZES.length - 1 && y < BRAIN_LAYER_SIZES[x] - 1) {
                    fill(0);
                    textAlign(LEFT);
                    text(languages[y],(x * drawWidth + 0.7) * scaleUp, (apY(x, y) +( neuronSize * 0.52)) * scaleUp);
                    textAlign(CENTER);
                }
            }
        }
    }

    public String coolify(double val) { // don't name you function coolify, call it what it does
        int v = (int)(Math.round(val * 100));
        if (v == 100) { return "1"; }
        else if (v < 10) { return ".0" + v; }
        else { return "." + v; }
    }

    public void drawAxon(int x1, int y1, int x2, int y2, float scaleUp) {
        double v = axons[x1][y1][y2] * neurons[x1][y1];
        if (Math.abs(v) >= 0.001){
            stroke(axonStrokeColor(axons[x1][y1][y2]));
            line(x1 * drawWidth * scaleUp, apY(x1, y1) * scaleUp, x2 * drawWidth * scaleUp, apY(x2, y2) * scaleUp);
        }
    }

    public int apY(int x, int y) {
        if (condenseLayerOne && x == 0) { return y / INPUTS_PER_CHAR; }
        else { return y; }
    }

    public color axonStrokeColor(double d) {
        if (d >= 0) { return color(255, 255, 255, (float)(d * 255)); }
        else { return color(1, 1, 1, abs((float)(d * 255))); }
    }

    public color neuronFillColor(double d) {
        return color((float)(d * 255), (float)(d * 255), (float)(d * 255));
    }

    public color neuronTextColor(double d){
        if (d >= 0.5) { return color(0, 0, 0); }
        else {return color(255, 255, 255); }
    }
}