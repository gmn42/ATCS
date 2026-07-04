package com.gpl.rpg.atcontentstudio.ui;

import com.gpl.rpg.atcontentstudio.model.GameSource;
import com.gpl.rpg.atcontentstudio.model.Project;
import com.gpl.rpg.atcontentstudio.model.ProjectTreeNode;
import com.gpl.rpg.atcontentstudio.model.Workspace;
import com.gpl.rpg.atcontentstudio.model.gamedata.GameDataSet;
import org.junit.Test;

import javax.swing.event.TreeModelEvent;
import javax.swing.event.TreeModelListener;
import javax.swing.tree.TreeNode;
import javax.swing.tree.TreePath;
import java.awt.*;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Enumeration;
import java.util.List;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertSame;

public class ProjectsTreeCacheTest {

    @Test
    public void cachesSortedChildrenAndPreservesDuplicateDescriptions() throws Exception {
        ProjectsTree.ProjectsTreeModel model = createModel();
        RecordingListener listener = new RecordingListener();
        model.addTreeModelListener(listener);

        DummyNode root = new DummyNode("root", null);
        DummyNode zeta = new DummyNode("zeta", root);
        DummyNode alpha1 = new DummyNode("alpha", root);
        DummyNode alpha2 = new DummyNode("alpha", root);
        DummyNode beta = new DummyNode("beta", root);

        assertSame(alpha1, model.getChild(root, 0));
        assertSame(alpha2, model.getChild(root, 1));
        assertSame(beta, model.getChild(root, 2));
        assertSame(zeta, model.getChild(root, 3));

        assertEquals(0, model.getIndexOfChild(root, alpha1));
        assertEquals(1, model.getIndexOfChild(root, alpha2));
        assertEquals(2, model.getIndexOfChild(root, beta));
        assertEquals(3, model.getIndexOfChild(root, zeta));

        DummyNode alpha3 = new DummyNode("alpha", root);
        model.insertNode(path(root, alpha3));

        assertSame(alpha1, model.getChild(root, 0));
        assertSame(alpha2, model.getChild(root, 1));
        assertSame(alpha3, model.getChild(root, 2));
        assertSame(beta, model.getChild(root, 3));
        assertSame(zeta, model.getChild(root, 4));
        assertEquals(2, listener.insertedIndexes.get(0).intValue());

        alpha2.rename("omega");
        model.changeNode(path(root, alpha2));

        assertSame(alpha1, model.getChild(root, 0));
        assertSame(alpha3, model.getChild(root, 1));
        assertSame(beta, model.getChild(root, 2));
        assertSame(alpha2, model.getChild(root, 3));
        assertSame(zeta, model.getChild(root, 4));
        assertEquals(1, listener.removedIndexes.get(0).intValue());
        assertEquals(3, listener.insertedIndexes.get(1).intValue());

        beta.rename("beta");
        model.changeNode(path(root, beta));
        assertEquals(2, listener.changedIndexes.get(0).intValue());

        root.children.remove(alpha1);
        model.removeNode(path(root, alpha1));
        assertSame(alpha3, model.getChild(root, 0));
        assertSame(beta, model.getChild(root, 1));
        assertSame(alpha2, model.getChild(root, 2));
        assertSame(zeta, model.getChild(root, 3));
        assertEquals(0, listener.removedIndexes.get(1).intValue());

        assertEquals(0, listener.structureChangedCount);
    }

    private static ProjectsTree.ProjectsTreeModel createModel() throws Exception {
        Path tempRoot = Files.createTempDirectory("atcs-tree-cache");
        File workspaceRoot = tempRoot.resolve("workspace").toFile();
        Workspace.activeWorkspace = new Workspace(workspaceRoot);
        ProjectsTree tree = new ProjectsTree();
        return tree.new ProjectsTreeModel();
    }

    private static TreePath path(DummyNode parent, DummyNode child) {
        return new TreePath(new Object[]{parent, child});
    }

    private static class RecordingListener implements TreeModelListener {
        private final List<Integer> insertedIndexes = new ArrayList<Integer>();
        private final List<Integer> removedIndexes = new ArrayList<Integer>();
        private final List<Integer> changedIndexes = new ArrayList<Integer>();
        private int structureChangedCount = 0;

        @Override
        public void treeNodesChanged(TreeModelEvent e) {
            changedIndexes.add(firstIndex(e));
        }

        @Override
        public void treeNodesInserted(TreeModelEvent e) {
            insertedIndexes.add(firstIndex(e));
        }

        @Override
        public void treeNodesRemoved(TreeModelEvent e) {
            removedIndexes.add(firstIndex(e));
        }

        @Override
        public void treeStructureChanged(TreeModelEvent e) {
            structureChangedCount++;
        }

        private int firstIndex(TreeModelEvent e) {
            return e.getChildIndices() == null || e.getChildIndices().length == 0 ? -1 : e.getChildIndices()[0];
        }
    }

    private static class DummyNode implements ProjectTreeNode {
        private String desc;
        private final DummyNode parent;
        private final List<DummyNode> children = new ArrayList<DummyNode>();

        DummyNode(String desc, DummyNode parent) {
            this.desc = desc;
            this.parent = parent;
            if (parent != null) {
                parent.children.add(this);
            }
        }

        void rename(String desc) {
            this.desc = desc;
        }

        @Override
        public void childrenAdded(List<ProjectTreeNode> path) {
        }

        @Override
        public void childrenChanged(List<ProjectTreeNode> path) {
        }

        @Override
        public void childrenRemoved(List<ProjectTreeNode> path) {
        }

        @Override
        public void notifyCreated() {
        }

        @Override
        public String getDesc() {
            return desc;
        }

        @Override
        public Project getProject() {
            return null;
        }

        @Override
        public GameDataSet getDataSet() {
            return null;
        }

        @Override
        public Image getIcon() {
            return null;
        }

        @Override
        public Image getOpenIcon() {
            return null;
        }

        @Override
        public Image getClosedIcon() {
            return null;
        }

        @Override
        public Image getLeafIcon() {
            return null;
        }

        @Override
        public GameSource.Type getDataType() {
            return null;
        }

        @Override
        public boolean isEmpty() {
            return children.isEmpty();
        }

        @Override
        public boolean needsSaving() {
            return false;
        }

        @Override
        public TreeNode getChildAt(int childIndex) {
            return children.get(childIndex);
        }

        @Override
        public int getChildCount() {
            return children.size();
        }

        @Override
        public TreeNode getParent() {
            return parent;
        }

        @Override
        public int getIndex(TreeNode node) {
            return children.indexOf(node);
        }

        @Override
        public boolean getAllowsChildren() {
            return true;
        }

        @Override
        public boolean isLeaf() {
            return children.isEmpty();
        }

        @Override
        public Enumeration<? extends TreeNode> children() {
            return Collections.enumeration(children);
        }
    }
}
