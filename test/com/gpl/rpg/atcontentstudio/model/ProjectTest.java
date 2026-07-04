package com.gpl.rpg.atcontentstudio.model;

import com.gpl.rpg.atcontentstudio.io.SettingsSave;
import org.junit.Test;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

public class ProjectTest {

    private static void createSourceLayout(File sourceRoot) {
        new File(sourceRoot, "res/raw").mkdirs();
        new File(sourceRoot, "res/xml").mkdirs();
        new File(sourceRoot, "res/drawable").mkdirs();
    }

    @Test
    public void jsonRoundTripPopulatesAllJsonBackedProjectFields() throws Exception {
        Path tempRoot = Files.createTempDirectory("atcs-project-json-roundtrip");
        File workspaceRoot = tempRoot.resolve("workspace").toFile();
        File sourceRoot = tempRoot.resolve("source").toFile();
        workspaceRoot.mkdirs();
        sourceRoot.mkdirs();
        createSourceLayout(sourceRoot);

        Workspace workspace = new Workspace(workspaceRoot);
        Project original = new Project(workspace, "demo-project", sourceRoot, Project.ResourceSet.allFiles);
        original.open = false;
        original.save();

        Project restored = new Project(workspace, new File(original.baseFolder, Project.SETTINGS_FILE_JSON));

        assertEquals("demo-project", restored.name);
        assertEquals(original.baseFolder.getAbsoluteFile(), restored.baseFolder.getAbsoluteFile());
        assertFalse(restored.open);
        assertEquals(Project.ResourceSet.allFiles, restored.sourceSetToUse);

        assertNotNull(restored.baseContent);
        assertEquals(GameSource.Type.source, restored.baseContent.type);
        assertEquals(sourceRoot.getAbsoluteFile(), restored.baseContent.baseFolder.getAbsoluteFile());
    }

    @Test
    public void legacyProjectFileIsMigratedAndLoadedThroughJsonPath() throws Exception {
        Path tempRoot = Files.createTempDirectory("atcs-project-legacy-roundtrip");
        File workspaceRoot = tempRoot.resolve("workspace").toFile();
        File sourceRoot = tempRoot.resolve("source").toFile();
        workspaceRoot.mkdirs();
        sourceRoot.mkdirs();
        createSourceLayout(sourceRoot);

        Workspace workspace = new Workspace(workspaceRoot);
        Project original = new Project(workspace, "legacy-project", sourceRoot, Project.ResourceSet.debugData);
        original.open = false;
        original.save();

        File projectRoot = original.baseFolder;
        File jsonFile = new File(projectRoot, Project.SETTINGS_FILE_JSON);
        File legacyFile = new File(projectRoot, Project.SETTINGS_FILE);
        SettingsSave.saveInstance(original, legacyFile, "Project");
        assertTrue(legacyFile.isFile());
        assertTrue(jsonFile.delete());

        Project restored = Project.fromFolder(workspace, projectRoot);

        assertNotNull(restored);
        assertTrue(jsonFile.isFile());
        assertEquals("legacy-project", restored.name);
        assertEquals(projectRoot.getAbsoluteFile(), restored.baseFolder.getAbsoluteFile());
        assertFalse(restored.open);
        assertEquals(Project.ResourceSet.debugData, restored.sourceSetToUse);
        assertNotNull(restored.baseContent);
        assertEquals(GameSource.Type.source, restored.baseContent.type);
        assertEquals(sourceRoot.getAbsoluteFile(), restored.baseContent.baseFolder.getAbsoluteFile());
    }
}
