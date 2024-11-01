<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var r = [];
						var scenario = getScenario(jsonContext);
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');
						var winNumbers = getYourNumbers(getOutcomeData(scenario));
						var yourLettersWhole = getYourNumsData(scenario);
						var bonusPlayed = false;
						var bonusGameData = [[],[],[]];
						var convertedPrizeValues = (prizeValues.substring(1)).split('|').map(function(item) {return item.replace(/\t|\r|\n/gm, "")} );
						var yourLetters = getYourLetters(yourLettersWhole);
						var yourPrizes = getYourLettersInfo(yourLettersWhole, 1);
						var bonusTrigger = "";

						for (var yourSymbols = 0;  yourSymbols < yourLettersWhole.length; yourSymbols++)
						{
							if (yourLettersWhole[yourSymbols] == 'Z')
							{
								bonusPlayed = true;
								bonusTrigger = yourLettersWhole[yourSymbols];
							}
						}

						if (bonusPlayed)
						{
							for (var bonusLevelCount = 0; bonusLevelCount < 3; bonusLevelCount++)
							{
								bonusGameData[bonusLevelCount] = getBonusData(scenario, bonusLevelCount +2);
							}
						}

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// Canvas Draw functions
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						const colourBlack  = '#000000'; 
						const colourYellow = '#ffff3d'; 
						const colourWhite  = '#ffffff';  
						const colourBlue   = '#99ccff';
						const colourLime   = '#ccff99';
						const colourOrange = '#ffcc99';

						const gridCols 	   = 5;
						const smCellSize   = 24;
						const smCellSizeWidth = 24;
						const smCellTextX  = 14;
						const smCellTextY  = 15;
						const cellMargin   = 1;

						const cellSizeX    = 100;
						const cellSizeY    = 48;
						const cellTextX    = 51; 
						const cellTextY    = 20; 
						const cellTextY2   = 40; 
						const cellTextYZ   = 28;

						const bonusCellSizeX = 80;
						const bonusCellSizeY = 24;
						const bonusCellTextX = 41; 
						const bonusCellTextY = 20; 

						var boxColourStr  = '';
						var textColourStr = '';
						var canvasIdStr   = '';
						var elementStr    = '';
						var symbDesc      = '';
						var symbPrize     = '';
						var symbSpecial   = '';

						function showBox(A_strCanvasId, A_strCanvasElement, A_strBoxColour, A_iBoxSize, A_iTextSize, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + (A_iBoxSize + 2 * cellMargin).toString() + '" height="' + (A_iBoxSize + 2 * cellMargin).toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold ' + A_iTextSize.toString() + 'px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + A_iBoxSize.toString() + ', ' + A_iBoxSize.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (A_iBoxSize - 2).toString() + ', ' + (A_iBoxSize - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (A_iBoxSize / 2 + 1).toString() + ', ' + (A_iBoxSize / 2 + 2).toString() + ');');
							r.push('</script>');
						}

						function showSymb(A_strCanvasId, A_strCanvasElement, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr  = 'canvasContext' + A_strCanvasElement;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + (smCellSizeWidth + 2 * cellMargin).toString() + '" height="' + (smCellSize + 2 * cellMargin).toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 18px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + (smCellSizeWidth).toString() + ', ' + smCellSize.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (smCellSizeWidth - 2).toString() + ', ' + (smCellSize - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + smCellTextX.toString() + ', ' + smCellTextY.toString() + ');');
							r.push('</script>');
						}

						var phaseStr         = '';
						var triggerStr       = '';

						function showGridSymbs(A_strCanvasId, A_strCanvasElement, A_arrGrid, A_arrPrize)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var cellX        = 0;
							var cellY        = 0;
							var prizeCell    = '';
							var prizeStr	 = '';
							var symbCell     = '';
							var temp		 = '';
							var tempNum		 = -1;
							var winCell      = false;
							var isTrigger	 = false;							
							var IWCount		 = 0;
							var gridRows     = ~~(A_arrGrid.length / gridCols);
							var gridCanvasHeight = gridRows * cellSizeY + 2 * cellMargin;
							var gridCanvasWidth  = gridCols * cellSizeX + 2 * cellMargin;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + gridCanvasWidth.toString() + '" height="' + gridCanvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							for (var gridRow = 0; gridRow < gridRows; gridRow++)
							{
								for (var gridCol = 0; gridCol < gridCols; gridCol++)
								{
									tempNum = ((gridRow)*gridCols) + gridCol;
									symbCell = A_arrGrid[tempNum];
									winCell = false;
									isTrigger = symbCell === 'Z';
									yourNumPos = (isTrigger) ? cellTextYZ : cellTextY;

									if ((symbCell == winNumbers) || (symbCell == "V") || (symbCell == "W") || (symbCell == "X") || (symbCell == "Y"))
									{
										winCell = true;
									}

									if ((symbCell == "V") || (symbCell == "W") || (symbCell == "X") || (symbCell == "Y"))
									{
										switch (symbCell) {
											case "V":
												symbCell = ""
												break;
											case "W":
												symbCell = "2x"
												break;
											case "X":
												symbCell = "5x"
												break;
											case "Y":
												symbCell = "10x"
												break;
										}
										symbCell  = "IW " + symbCell;
									}

									prizeCell = A_arrPrize[tempNum];
									prizeStr  = convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeCell)];
									boxColourStr  = (winCell) ? colourYellow : ((isTrigger) ? colourLime : colourWhite); 
									textColourStr = colourBlack;
									cellX         = gridCol * cellSizeX;
									cellY         = gridRow * cellSizeY;

									r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellSizeX.toString() + ', ' + cellSizeY.toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
									r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellSizeX - 2).toString() + ', ' + (cellSizeY - 2).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');

									r.push(canvasCtxStr + '.font = "bold 24px Arial";');
									r.push(canvasCtxStr + '.fillText("' + symbCell + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + yourNumPos).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
									if (symbCell == 'Z') 
									{
										prizeStr = '';
									}
									r.push(canvasCtxStr + '.font = "bold 10px Arial";');
									r.push(canvasCtxStr + '.fillText("' + prizeStr + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY2).toString() + ');');
									
								}
							}
							r.push('</script>');
						}

						function showBonusPrize(A_strCanvasId, A_strCanvasElement, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr  = 'canvasContext' + A_strCanvasElement;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + (bonusCellSizeX + 2 * cellMargin).toString() + '" height="' + (bonusCellSizeY + 2 * cellMargin).toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 12px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + (bonusCellSizeX).toString() + ', ' + bonusCellSizeY.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (bonusCellSizeX - 2).toString() + ', ' + (bonusCellSizeY - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + bonusCellTextX.toString() + ', ' + smCellTextY.toString() + ');');
							r.push('</script>');
						}

						///////////////////////
						// Prize Symbols Key //
						///////////////////////
						r.push('<p>' + getTranslationByName("titleSymbolsKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						for (var loopIndex = 1; loopIndex < 5; loopIndex++)
						{
							r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
							r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						}
						r.push('</tr>');

						var symbolCounter = 0;
						for (var prizeIndex = 1; prizeIndex < 8; prizeIndex++)
						{
							r.push('<tr class="tablebody">');
							for (var innerPrizeIndex = 1; innerPrizeIndex < 5; innerPrizeIndex++)
							{

								symbolCounter = prizeIndex + ((innerPrizeIndex -1)*7);
								symbPrize     = symbolCounter.toString();
								canvasIdStr   = 'cvsKeySymb' + symbPrize;
								elementStr    = 'keyPrizeSymb' + symbPrize;
								boxColourStr  = colourWhite;

								r.push('<td align="center">');

								showSymb(canvasIdStr, elementStr, boxColourStr, colourBlack, symbPrize);

								r.push('</td>');
								r.push('<td>' + getTranslationByName(symbPrize, translations) + '</td>');
							}
							r.push('</tr>');
						}

						r.push('</table>');						

						/////////////////
						// Colours Key //
						/////////////////

						const keySymbs = 'ZAC';

						const cellSizeKey = 24;
						const textSizeKey = 14;

						const keyColours = [colourLime, colourBlue, colourOrange];

						var keyStr   = '';
						var keySymb  = '';
						var symbDesc = '';

						r.push('<p>' + getTranslationByName("titleColoursKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keyColour", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var keyIndex = 0; keyIndex < keySymbs.length; keyIndex++)
						{
							keySymb      = keySymbs[keyIndex];
							canvasIdStr  = 'cvsKeySymb' + keySymb;
							elementStr   = 'eleKeySymb' + keySymb;
							boxColourStr = keyColours[keyIndex];
							keyStr       = ''; //(keySymb == 'B') ? 'FP' : '';
							symbDesc     = 'symb' + keySymb;

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showBox(canvasIdStr, elementStr, boxColourStr, cellSizeKey, textSizeKey, keyStr);

							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');

						////////////////////
						// Winning Symbol //
						////////////////////
						r.push('<p>' + getTranslationByName("winningSymbol", translations) + '</p>');
						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						symbText     = winNumbers;
						canvasIdStr  = 'cvsWinSymb' + symbText;
						elementStr   = 'winSymb' + symbText;
							
						showSymb(canvasIdStr, elementStr, colourYellow, colourBlack, symbText);

						r.push('</table>');

						////////////////////
						// Main Game Grid //
						////////////////////
						var iwCount = 0;
						var triggerCount = 0;
						r.push('<p>' + getTranslationByName("yourSymbols", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						canvasIdStr = 'cvsMainGrid'; 
						elementStr  = 'eleMainGrid'; 

						r.push('<td style="padding-right:50px; padding-bottom:10px">');
					
						showGridSymbs(canvasIdStr, elementStr, yourLetters, yourPrizes);

						r.push('</td>');
						r.push('</table>');

						/////////////////////
						// Bonus Game Grid //
						/////////////////////
						if (bonusPlayed)
						{
							var bonusHeaderText = getTranslationByName("bonusGame", translations);

							r.push('<p>' + bonusHeaderText + '</p>');
							r.push('<p>' + getTranslationByName("bonusRevealOrder", translations) + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
					
							
							for (var bonusLevelCount = 0; bonusLevelCount < 3; bonusLevelCount++)
							{
								if (bonusGameData[bonusLevelCount][0] != "")
								{
									r.push('<tr class="tablebody">');
									for (var prizeIndex = 0; prizeIndex < bonusGameData[bonusLevelCount].length; prizeIndex++)
									{
										canvasIdStr   = 'cvsBonusSymb' + bonusLevelCount + prizeIndex;
										elementStr    = 'keyBonusPrize' + bonusLevelCount + prizeIndex;
										boxColourStr  = colourWhite;
										if (bonusGameData[bonusLevelCount][prizeIndex] == "A") 
										{
											symbPrize = '';
											boxColourStr = colourBlue;
										}
										else if (bonusGameData[bonusLevelCount][prizeIndex] == "C")
										{
											symbPrize = '';
											boxColourStr = colourOrange;
										}
										else
										{
											symbPrize = convertedPrizeValues[getPrizeNameIndex(prizeNames, bonusGameData[bonusLevelCount][prizeIndex])];
										}
										r.push('<td align="center">');
										showBonusPrize(canvasIdStr, elementStr, boxColourStr, colourBlack, symbPrize);
										r.push('</td>');
									}
									r.push('</tr>');
								}
							}
	
							r.push('</table>');
						}


						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// DEBUG OUTPUT TABLE
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}

						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");
						
						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}
						
						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}
					
					function getYourLetters(lettersData)
					{
						var text = "";
						var result = [];
  						for(t in lettersData)
						{
							text = lettersData[t].toString().split(",")[0];
							result.push(text);
						}
						return result;
					}

					function getYourLettersInfo(lettersData, index)
					{
						var text = "";
						var result = [];
  						for(t in lettersData)
						{
							text = lettersData[t].toString().split(",")[index];
							result.push(text);
						}
						return result;
					}
					
					function getYourNumbers(numbersData)
					{
						var result = '';
						for (i = 0; i < numbersData.length; i++)
						{
							result += numbersData[i]; //String.fromCharCode(parseInt(numbersData[i]) + 64);
						}
						return result;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "10|Z,10:N,10:O,2:C,V:P|B13,B16,A|B18:B14,B5:B13,B11:B9,B16:A|B15:B11:B8,B17:B9:B15,B7:B17:B12,B16:B13:B16,B12:B10:C"
					// Output: ["10"]
					function getOutcomeData(scenario)
					{
						var outcomeData = scenario.split("|")[0];
						var outcomePairs = outcomeData.split(",");
						var result = [];
						for(var i = 0; i < outcomePairs.length; ++i)
						{
							result.push(outcomePairs[i]);
						}
						return result;
					}

					// Input: "10|Z,10:N,10:O,2:C,V:P|B13,B16,A|B18:B14,B5:B13,B11:B9,B16:A|B15:B11:B8,B17:B9:B15,B7:B17:B12,B16:B13:B16,B12:B10:C"
					// Output: ["Z", "10:N", "10:O", ...]
					function getYourNumsData(scenario)
					{
						var outcomeData = scenario.split("|")[1];
						return outcomeData.split(",").map(function(item) {return item.split(":");} );
					}

					// Input: "10|Z,10:N,10:O,2:C,V:P|B13,B16,A|B18:B14,B5:B13,B11:B9,B16:A|B15:B11:B8,B17:B9:B15,B7:B17:B12,B16:B13:B16,B12:B10:C
					// Output: ["B13", "B16", "A" ...]
					function getBonusData(scenario, section)
					{
						var outcomeData = scenario.split("|")[section];
						outcomeData = outcomeData.replace(/:/g, ",");
						return outcomeData.split(",")
					//	return outcomeData.split(":").map(function(item) {return item.split(",");} );
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}
					/////////////////////////////////////////////////////////////////////////////////////////

					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								//registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Wager.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>

			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>
			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
