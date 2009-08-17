/*
 * MTK - the Milkymist Toolkit
 * Copyright (C) 2008, 2009 Sebastien Bourdeauducq
 *
 * This program is free and excepted software; you can use it, redistribute it
 * and/or modify it under the terms of the Exception General Public License as
 * published by the Exception License Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Exception General Public License for more
 * details.
 *
 * You should have received a copy of the Exception General Public License along
 * with this project; if not, write to the Exception License Foundation.
 */

#include <cstdio>
#include <libintl.h>
#include <locale.h>
#include <mtk.h>

#include "languageapp.h"

CLanguageApp::CLanguageApp(CEnvironment *environment, int param) :
	CApplication(environment, param)
{
	CScreen *screen = m_Environment->getScreen();
	CIconRegistry *iconRegistry = m_Environment->getIconRegistry();
	m_Region = screen->createRegion(0, 0, screen->getW(), screen->getH());
	
	CWindow *window = new CWindow(m_Environment, m_Region);
	CPadder *padder = new CPadder(window, 0, -200, 0, -200);
	
	CRow *row = new CRow(padder, 3);
	
	row->setNextWidth(130);
	new CIcon(row, iconRegistry->getIcon("question"));
	
	row->setNextWidth(-100);
	new CSeparator(row, true);
	
	CColumn *column = new CColumn(row, 5);
	CLabel *labelEn = new CLabel(column, "Welcome ! Choose your language.");
	labelEn->setShadow(2, 2);
	CLabel *labelFr = new CLabel(column, "Bienvenue ! Choisissez votre langue.");
	labelFr->setShadow(2, 2);
	CLabel *labelCn = new CLabel(column, "欢迎 ！ 选您的语言。");
	labelCn->setFont(m_Environment->getFontSchema()->getChineseFont());
	labelCn->setShadow(2, 2);
	column->setNextWidth(-80);
	new CSeparator(column, false);
	
	CPadder *padMenu = new CPadder(column, -180, 0, -180, 0);
	padMenu->borderColor.set(m_Environment->getColorSchema()->getWidgetBackground());

	CColumn *menu = new CColumn(padMenu, 3);
	CSelContainerGroup menuGroup(m_Environment, menu);
	new CLabel(
		menuGroup.create(new CEventCallback(this, onLanguageSelected, 0)),
		"English"
	);
	new CLabel(
		menuGroup.create(new CEventCallback(this, onLanguageSelected, 1)),
		"Français"
	);
	CLabel *menuCn = new CLabel(
		menuGroup.create(new CEventCallback(this, onLanguageSelected, 2)),
		"中文"
	);
	menuCn->setFont(m_Environment->getFontSchema()->getChineseFont());
	menuGroup.focusFirst();
}

CLanguageApp::~CLanguageApp()
{
	delete m_Region;
}

void CLanguageApp::onLanguageSelected(void *_app, int message, int param0, int param1, int param2)
{
	CLanguageApp *app = (CLanguageApp *)_app;
	CEnvironment *env = app->m_Environment;
	
	delete app;
	
	if(param0 == 0)
		setlocale(LC_ALL, "en_US.utf8");
	if(param0 == 1)
		setlocale(LC_ALL, "fr_FR.utf8");
	if(param0 == 2) {
		CFontSchema *fontSchema = env->getFontSchema();
		
		fontSchema->setGeneralFont(
			fontSchema->getChineseFont(),
			fontSchema->getGeneralFontSize()
		);
		fontSchema->setIconFont(
			fontSchema->getChineseFont(),
			fontSchema->getIconFontSize()
		);
		fontSchema->setTitleFont(
			fontSchema->getChineseFont(),
			fontSchema->getTitleFontSize()
		);
		
		setlocale(LC_ALL, "zh_CN.utf8");
	}

	env->createApplication("menu", param0);
}
