package act_ingest;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;

import com.opencsv.*;
import org.apache.commons.lang3.StringUtils;

public class Main {
    public Main() throws IOException {
    }

    public static void main(String[] args) throws IOException {
        File dir = new File("../i2b2ACT to HPDS Data/");
        String valueRef = "src/main/resources/value_output.txt";

        List<String> pathList = new ArrayList<String>();
        List<String> datasetList = new ArrayList<String>();
        Map<String, String> categoricalVars = new HashMap<>();
        Map<String, String> continuousVars = new HashMap<>();

        try (BufferedReader lines = Files.newBufferedReader(Paths.get(valueRef))) {
            String line = lines.readLine();
            while (line != null) {
                if (line.contains("path:")) {

                    String path = line.substring(line.indexOf(':') + 2);
                    String valLine = lines.readLine();

                    if (valLine.contains("values:")) {
                        categoricalVars.put(path, valLine.substring(valLine.indexOf(':') + 2));

                    } else if (valLine.contains("range:")) {
                        continuousVars.put(path, valLine.substring(valLine.indexOf(':') + 2));
                    } else {
                        System.err.println("No vals found for " + path);
                    }

                }
                line = lines.readLine();
            }
        }
        catch (Exception e){
            e.printStackTrace();
        }
        System.out.println("Continuous vars:" + continuousVars.size());
        System.out.println("Categorical vars:" + categoricalVars.size());

        List<File> dsvList = Arrays.stream(Objects.requireNonNull(dir.listFiles((directory, name) -> name.toLowerCase().endsWith(".dsv")))).toList();
        dsvList.forEach(
        dsv-> {
                    CSVParser csvParser = new CSVParserBuilder().withSeparator(';').withEscapeChar('φ').build();
                    try (CSVReader buffer = new CSVReaderBuilder(Files.newBufferedReader(Paths.get(dsv.getPath()))).withCSVParser(csvParser).withSkipLines(1).build()) {

                        pathList.addAll(buffer.readAll().stream().map(line -> line[3]).toList());
                        System.out.println("Path list size: " + pathList.size());
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }

        }
        );


        List<String[]> concepts = new ArrayList<>();

        concepts = pathList.stream().sorted(new Comparator<String>() {
            @Override
            public int compare(String o1, String o2) {
                if (o1.length() == o2.length()) {
                    return o1.compareTo(o2);
                }
                return o1.length() - (o2.length());
            }
        }).distinct().map(path -> {
            String[] nodes = StringUtils.strip(path, "\\").split("\\\\");
            String datasetRef = nodes[0];
            if (!datasetList.contains(datasetRef)) {
                datasetList.add(datasetRef);
            }
            String name = nodes[nodes.length - 1];
            String conceptType = continuousVars.containsKey(path) ? "Continuous" : "Categorical";
            String conceptPath = (path.endsWith("\\") ? path : path + "\\").replaceAll("\\\\","\\\\\\\\");
            String parentConceptPath = (path.substring(0, path.lastIndexOf("\\") + 1)).replaceAll("\\\\","\\\\\\\\");
            String values = "";
            if (continuousVars.containsKey(conceptPath)) {
                values = continuousVars.get(conceptPath);
            } else if (categoricalVars.containsKey(conceptPath)) {
                values = categoricalVars.get(conceptPath);
            }
            return new String[]{datasetRef, name, name, conceptType, conceptPath, parentConceptPath, values, name};
        }).toList();
        CSVWriter datasetWriter = new CSVWriter(Files.newBufferedWriter(Paths.get("output/datasets.csv")));
        String[] datasetHeader = {"ref", "full_name", "abbreviation", "description"};
        datasetWriter.writeNext(datasetHeader);
        datasetWriter.writeAll(datasetList.stream().map(dataset -> new String[]{dataset, dataset, "", ""}).toList());
        datasetWriter.close();
        int conceptCount = concepts.size();
        for(int i = 0; i< conceptCount; i += 10000 ){
            int endIndex = i+10000;
            if (endIndex > conceptCount-1){
                endIndex = conceptCount-1;
            }
            List<String[]> subsetConcepts = concepts.subList(i, endIndex);
            CSVWriter conceptsWriter = new CSVWriter(Files.newBufferedWriter(Paths.get("output/concepts_"+ i +".csv")));
            String[] conceptsHeader = {"dataset_ref", "name", "display", "concept_type", "concept_path", "parent_concept_path", "values", "description"};
            conceptsWriter.writeNext(conceptsHeader);
            conceptsWriter.writeAll(subsetConcepts);
            conceptsWriter.close();
        }

    }
}