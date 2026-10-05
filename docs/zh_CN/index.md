<!-- translation of docs/en/index.md @ 0499e77e2e07 -->
# 文档

[English](../en/index.md) · [Español](../es/index.md) · [日本語](../ja/index.md) · [Português (Brasil)](../pt_BR/index.md) · [Русский](../ru/index.md) · [Türkçe](../tr/index.md) · **简体中文**

> 本文是[英文原文](../en/index.md)的翻译。两者不一致时，以英文版为准。

适用于 Godot 4.7 等距视角和俯视角 RPG 的点击移动角色控制器与环绕相机，附带两个演示关卡。概览请先阅读 [README](../../README.zh_CN.md)。

英文文档先行维护，是各译本的参考依据；翻译可能略有滞后。

## 首次完成集成

1. [运行演示](getting-started.md)，试用默认操作。
2. 在自己的项目中建一个小关卡并[迁移英雄](integration.md#将演示中的英雄迁移到你的项目)。修改角色前，先完成文件复制、输入映射和导航步骤。
3. [选择配置方案](configurations.md)：手动环绕、鼠标沿路径移动，或跟随相机探索。
4. 参考[移动](systems/locomotion.md)、[输入](systems/input.md)和[相机](systems/camera.md)调整各项属性；[角色](systems/characters.md)说明如何替换模型并添加动画。

## 文档菜单

请从下方选择页面。各系统参考之后还列有插件配置指南。

### 入门

- [快速上手](getting-started.md)：环境要求、打开项目、演示中有什么。
- [操作](controls.md)：所有输入、点击与按住、配合右键的按键、相机。
- [设置](settings.md)：设置窗口中的每个选项、它的键名、默认值及作用。
- [英雄配置方案](configurations.md)：参数来源、精确节点路径、三种相互协调的配置及其验证方法。

### 代码

- [架构](architecture.md)：主场景、一个物理帧内的数据流、各个组件以及这样拆分的原因。
- [在你的项目中使用](integration.md)：各插件及其需求、单独使用相机、点击移动、迁移英雄、使用自己的身体及 NPC。
- [项目配置](project-setup.md)：组件所需的物理层、输入动作、分组和项目设置。

### 系统

- [移动](systems/locomotion.md)：`LocomotionSettings`、`GroundMotion`、`NavigationMover`、`GroundCharacter`，角色为动画和界面报告的信息、`CharacterMonitor`、台阶和斜坡，冲刺与体力、跳跃、下落（`FallSettings`）及边缘防护。
- [相机](systems/camera.md)：`OrbitCameraRig`（环绕、缩放曲线、跟随）和 `CameraArm`（障碍物、拉近、淡化）。
- [输入](systems/input.md)：`PointClickMoveInput`（点击、按住、按键、光标）和 `CharacterActionInput`。
- [角色](systems/characters.md)：模型与装备、英雄外观、手部摆动、悬浮和剪影。
- [音频](systems/audio.md)：角色声音及其合成方式。
- [UI](systems/ui.md)：窗口、设置系统和设置窗口、HUD、主题、翻译。
- [世界与导航](systems/world-and-navigation.md)：关卡、地点、表面与烘焙纹理、山、导航网格及其重新烘焙方法。
- [关卡](systems/levels.md)：游戏框架、关卡容器与加载画面、传送门和出生点、可操控的英雄及孤岛。

### 插件设置指南

- [点击移动组件](../../addons/iso_orbit/click_to_move/README.zh_CN.md)
- [地面角色](../../addons/iso_orbit/ground_character/README.zh_CN.md)
- [环绕相机](../../addons/iso_orbit/orbit_camera/README.zh_CN.md)
- [遮挡剪影](../../addons/iso_orbit/occluded_silhouette/README.zh_CN.md)
- [兴趣点](../../addons/iso_orbit/points_of_interest/README.zh_CN.md)
- [界面窗口](../../addons/iso_orbit/ui_screens/README.zh_CN.md)
- [关卡切换](../../addons/iso_orbit/levels/README.zh_CN.md)

### 维护

- [测试](testing.md)：如何运行、各测试套件覆盖的内容、如何编写检查。
- [已知问题](known-issues.md)：项目局限与引擎怪癖，以及应对方法。
- [术语表](glossary.md)：代码和文档中使用的术语。
- [路线图](roadmap.md)：计划中的工作。

---

*本页对应 Iso & Orbit 1.2.0。*
