########################################################################
#                          | Auteur :    GBU     | Creation 21/10/2016 #
########################################################################
# DESCRIPTIF  : Script de d'intégration DESADVs                        #
#                                                                      #
#                                                                      #
#                                                                      #
#                                                                      #
# APPEL       : aucun                                                  #
#                                                                      #
########################################################################
# MODIFICATIONS | qui | ../../.. | Commentaires                        #
########################################################################
VERSION=2.0
#------------------------------------------------------------------------------#
#  VERIFICATION NOMBRE D ARGUMENTS                                             #
#------------------------------------------------------------------------------#
if [ $# -ne 1 ]
    then
    echo "Merci de saisir : test.bat <desadv_001>"
    exit 0
fi


DESADV=$1

#------------------------------------------------------------------------------#
#  DEFINITION TRAITEMENT                                                       #
#------------------------------------------------------------------------------#

#*** Répertoire de traitement ********* # **************************************

FIC=$ENV/fic                            # Localisation des fichiers 
INIT=$ENV/init
SECU=$ENV/secu
LOG=$ENV/log

BASE=prodmagdb                          # Base de traitement magasin
BASE_A=articledb                        # Base de traitement magasin
LM=/home2/lm                            # Environnement general
ENV=$PWD                                # Environnement general

SQL=$ENV                                # Localisation des sql
SQLEXE="$LM/prog/util/bin/sqlexe.exe -s" #
SQLEXE_TMP=$FIC                         #
export SQLEXE_TMP                       #
WC="wc -l"

#*** Répertoire d'integration ********* # **************************************

ARR_ENT=$LM/prog/itf_transfert/trf/arrivee/FLUXDESADV
ARR_DIR=$LM/prog/itf_transfert/trf/arrivee/DESADV_001
LOG=$ENV/log                            # Localisation des fichiers logs
BAT=$ENV/bat                            # Localisation des bat
SQL=$ENV/sql                            # Localisation des sql

ATT=${LM}/prog/rpc/fic/desadv/attente   # Répertoire de desadv en attente
SECU=${LM}/prog/rpc/fic/desadv/secu     # Répertoire de desadv sécurisé
REJ=${LM}/prog/rpc/fic/desadv/rejet     # Répertoire de desadv sécurisé


#*** Retour de traitement ************* # **************************************

RET_OK=0
RET_NOK=1
RET_ABORT=64

#*** Fichiers LOG ********************* # **************************************

LOGTRA=$LOG'/'$TRT'.'log                # Fichier rapport de traitement
LOGERR=$LOG'/'$TRT'.'err                # Fichier rapport des anomalies
LOGSTEP=$LOG'/'$TRT'.'step              # Fichier memorisation du step
LOGIND=$LOG'/'$TRT'.'ind                # Temoin traitement

#*** Fichiers Entree ****************** # **************************************

COLISAGE=`grep "REF_" ${DESADV} | cut -c7-21 | sed 's/ //g'`

[ "${COLISAGE}" == " " ] && echo "Le desadv ne contient pas de ligne REF_ ..." && exit 1

CDE=cde_${DESADV}.txt
CCD=client_cmd_${DESADV}.txt
DES=des_${DESADV}.txt
LIG=lig_${DESADV}.txt
LCD=ligne_cmd_${DESADV}.txt
MCD=mescde_${DESADV}.txt
ART=article_${DESADV}.txt
ARF=artfou_${DESADV}.txt
EAN=eanlm_${DESADV}.txt
CBL=cblm_${DESADV}.txt
FOU=fourcom_${DESADV}.txt
FOS=foursond_${DESADV}.txt

export ${CDE} ${CCD} ${DES} ${LIG} ${LCD} ${MCD} ${ART} ${ARF} ${EAN} ${CBL} ${FOU} ${FOS} ${COLISAGE}

FKZ=${DESADV}.KZ

#*** Fichiers de traitement *********** # **************************************

MONBAT=monte_desadv_from_prod.bat
MONSQL=monte_desadv_from_prod.sql
PURBAT=purge_desadv.bat
PURSQL=purge_desadv.sql

#*** Dates **************************** # **********************************

DATEJOUR=`date +"%Y%m%d"`




#------------------------------------------------------------------------------#
#  CREATION DES REPERTOIRES                                                    #
#------------------------------------------------------------------------------#
mkdir -p $LOG





#--------------------------------------------------------------------------#
#  BOUCLE DE TRAITEMENT                                                    #
#--------------------------------------------------------------------------#
echo "#################################################################################"
echo "#################################################################################"
echo "#####                                                                        ####"
echo "#####    ######     #########  #########     ###     ######     ##     ##    ####"
echo "#####    #######    #########  #########    ## ##    #######    ##     ##    ####"
echo "#####    ##    ###  ##         ##          ##   ##   ##    ###  ##     ##    ####"
echo "#####    ##     ##  ######     #########  ##     ##  ##     ##  ##     ##    ####"
echo "#####    ##     ##  ######     #########  #########  ##     ##  ##     ##    ####"
echo "#####    ##    ###  ##                ##  ##     ##  ##    ###   ##   ##     ####"
echo "#####    #######    #########  #########  ##     ##  #######      ## ##      ####"
echo "#####    ######     #########  #########  ##     ##  ######        ###       ####"
echo "#####                                                                        ####"
echo "#################################################################################"
echo "#################################################################################"
echo "#####                       Version $VERSION                                 ####"
echo "#####                       DATE  = $DATEJOUR                                ####"
echo "#################################################################################"
echo "#################################################################################"
echo "$STEP DEBUT `date`" > $LOGIND

while [ -f $LOGIND ]
do
    # ---------------------------
    # DESIGNATION DES TRAITEMENTS
    # ---------------------------
    case $STEP in
        "DEBTRA") LIBSTEP="DEBUT DE TRAITEMENT                                       ";;
        "RECFIC") LIBSTEP="RECUPERATION DES FICHIERS NECESSAIRE A L INTEGRATION      ";;
        "PURDES") LIBSTEP="PURGE DES DONNEES DU DESADV EN BASE                       ";;
        "MONDTA") LIBSTEP="REMONTEE DES DONNEES DESADV EN BASE                       ";;
               *) echo "TRAITEMENT INCONNU ($STEP)" ; break  ;;                    
    esac



    # -------------------------
    # INITIALISATION TRAITEMENT
    # -------------------------

    if [ $STEP != "DEBTRA" ]
    then
        echo "###################"
        echo "#########################"
        echo "###############################"
        echo "==$STEP==$LIBSTEP==`date +\"%d/%m/%Y %H:%M:%S\"`=="
        echo "###############################"
        echo "#########################"
        echo "###################"

        RETOUR=0
    fi

    # ----------
    # TRAITEMENT
    # ----------

    echo "$STEP ENCOURS `date`" > $LOGIND

    case $STEP in

        "DEBTRA") ## DEBUT DE TRAITEMENT
                
                ## CREATION DES REPERTOIRES 

                [ ! -d $LOG ] && mkdir -p $LOG

                # Suppression des desadvs en attente et en rejet
                rm -f ${ARR_ENT}/blvi_*
                rm -f ${ARR_DIR}/f_*
                rm -f ${ATT}/blvi_* ${ATT}/f_*
                rm -f ${REJ}/blvi_* ${REJ}/f_*

                ;;

        "RECFIC") ## RECUPERATION DES FICHIERS NECESSAIRE A L INTEGRATION

                ## PHASE 0 -- INITIALISATION

                RETOUR=${RET_OK}
                MANQUANT=""

                ## PHASE 1 -- VERIFICATION KZ

                [ ! - f ${CDE} ] && [ ! -s ${CDE} ] && echo "Merci de récupérer les données avec le script de récupération" && exit 1

                ## PHASE 2 -- DECAPSULATION DU KZ

                RETOUR=$?
                [ ${RETOUR} -ne ${RET_OK} ] && echo "Erreur -- Erreur dans la décapsulation ..." && exit 1


                ## PHASE 3 -- VERIFICATION DES FICHIERS DECAPSULES

                # Fichier de d'entête de commande
                [ ! - f ${CDE} ] && [ ! -s ${CDE} ] && echo "${CDE} " >> ${MANQUANT}  
                # Fichier des clients des commandes
                [ ! - f ${CCD} ] && [ ! -s ${CCD} ] && echo "${CCD} " >> ${MANQUANT}  
                # Fichier de désignation
                [ ! - f ${DES} ] && [ ! -s ${DES} ] && echo "${DES} " >> ${MANQUANT}  
                # Fichier des lignes de commandes
                [ ! - f ${LIG} ] && [ ! -s ${LIG} ] && echo "${LIG} " >> ${MANQUANT}  
                # Fichier des lignes de commandes CC
                [ ! - f ${LCD} ] && [ ! -s ${LCD} ] && echo "${LCD} " >> ${MANQUANT}  
                # Fichier de message de commande
                [ ! - f ${MCD} ] && [ ! -s ${MCD} ] && echo "${MCD} " >> ${MANQUANT} 
                # Fichier de liste d'article - Article
                [ ! - f ${ART} ] && [ ! -s ${ART} ] && echo "${ART} " >> ${MANQUANT}
                # Fichier de liste d'article fournisseur - Artfou
                [ ! - f ${ARF} ] && [ ! -s ${ARF} ] && echo "${ARF} " >> ${MANQUANT}
                # Fichier de liste d'article - Eanlm
                [ ! - f ${EAN} ] && [ ! -s ${EAN} ] && echo "${EAN} " >> ${MANQUANT}
                # Fichier de liste d'article à conditionnement logistique - Cblm
                [ ! - f ${CBL} ] && [ ! -s ${CBL} ] && echo "${CBL} " >> ${MANQUANT}
                # Fichier des fournisseurs des commandes
                [ ! - f ${FOU} ] && [ ! -s ${FOU} ] && echo "${FOU} " >> ${MANQUANT}
                # Fichier des sondages fournisseurs
                [ ! - f ${FOS} ] && [ ! -s ${FOS} ] && echo "${FOS} " >> ${MANQUANT}

                ## PHASE 4 -- VERIFCATION DES SCRIPTS

                [ ! - f ${MONBAT} ] && [ ! -s ${MONBAT} ] && echo "${MONBAT} " >> ${MANQUANT}  
                [ ! - f ${MONSQL} ] && [ ! -s ${MONSQL} ] && echo "${MONSQL} " >> ${MANQUANT}  
                [ ! - f ${PURBAT} ] && [ ! -s ${PURBAT} ] && echo "${PURBAT} " >> ${MANQUANT}  
                [ ! - f ${PURSQL} ] && [ ! -s ${PURSQL} ] && echo "${PURSQL} " >> ${MANQUANT} 

                ## PHASE 5 -- VERIFICATION DES ERREURS

                [ ! -s ${MANQUANT} ] && echo "Les fichiers suivants sont manquants : ${MANQUANT}" && RETOUR=${RET_NOK}

                [ ${RETOUR} == ${RET_OK} ] && echo "Les fichiers d'intégration sont bien présents !"
                [ ${RETOUR} != ${RET_OK} ] && echo "Veuillez effectuer une remontée des données de la production pour faire l'intégration du desadv !"


                ;;

        "PURDES") ## PURGE DES DONNEES DU DESADV EN BASE && REMONTEE DES DONNEES DESADV EN BASE
                
                
                ${SQLEXE} ${BASE} ${BASE_A} < ${PURSQL}

                if [ ${LIST_FIC} != 0 ]
                    then



                ;;

        "MONDTA") ## REMONTEE DES DONNEES DESADV EN BASE



        if [ ${LIST_FIC} != 0 ]
            then



        ;;

        "TRTADV") ## LANCEMENT DU TRAITEMENT D INTEGRATION
                
                                



                ;;


        esac

        #
        # TRAITEMENT DES ERREURS
        # ----------------------
        if [ $STEP != "DEBTRA" ]
        then
            if [ $RETOUR -eq $RET_OK ]
            then
                echo "$STEP FINI `date`" > $LOGIND
                echo "  -----> $STEP TERMINE NORMALEMENT"
            elif [ $RETOUR -lt $RET_ABORT ]
            then
                echo "$STEP FINI `date`" > $LOGIND
                echo "  -----> $STEP TERMINE AVEC MESSAGES ($RETOUR)"
            else
                echo "$STEP ERREUR `date`" > $LOGIND
                echo "  -----> $STEP TERMINE ANORMALEMENT ($RETOUR)"
                STEP="FINERR"
            fi
        fi

        #
        # ENCHAINEMENT DES TRAITEMENTS
        # ----------------------------
        case $STEP in
            "DEBTRA") STEP="VERFIC";;
            "VERFIC") 
                    if [ "${OPTION}" == "-ATT" ]
                        then
                            STEP="VERATT"
                        else
                            STEP="PURDES"
                    fi
                    ;;            
            "VERATT") STEP="PURDES";;
            "PURDES") STEP="MONDTA";;
        esac


done

exit 0





purge_desadv.bat $1 FORCE

if [ $? -eq 1 ] 
then
  monte_desadv_from_prod.bat $1                                                 

  sleep 5

#  /home2/lm/prog/util/bin/sqlexe.exe -s prodmagdb <update_lig.sql 1=$1

  if [ $? -eq 0 ] 
  then
     /home2/lm/prog/rpc/bat/brpc_trtadv.bat
  fi

fi
