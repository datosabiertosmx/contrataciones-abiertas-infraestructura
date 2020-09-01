// modelos para infraestructura
const db = require('../../models');
// PostgreSQL database
var db_conf = require('../../db_conf');
// moment format
var moment = require('moment'); // require
const { isNotNullOrEmpty } = require('../../utilities/validation-rules');

module.exports = {
    createPlanningPartyUnits: async function(data){
        var planningUnits = await db.planning_party_unit.findAll({
            attributes: { exclude: ['createdAt','updatedAt']},
            where : {contractingprocess_id: data.contractingprocess_id}
        });
        if(planningUnits !== undefined){
            planningUnits.forEach(async element => {
                await db.planning_party_unit.destroy({
                    where: {id: element.id}
                })
            });
        }
        if(data.requestingunits !== ""){
            if(Array.isArray(data.requestingunits)){
                data.requestingunits.forEach(async element =>{
                    if(element !== ""){
                        var arrayRequestingunits = element.split('/');
                        var code = arrayRequestingunits[0];
                        var name = arrayRequestingunits[1];
                        var requestingUnitLegalName = await db_conf.edca_db.oneOrNone('select identifier_legalname from parties p join roles r on p.id = r.parties_id where p.contractingprocess_id = $1 and r.requestingunit = true and p.partyid = $2 and p.name = $3 order by p.id', [data.contractingprocess_id,code,name]);
                        await db.planning_party_unit.create({
                            contractingprocess_id: parseInt(data.contractingprocess_id, 10),
                            party_code: code,
                            party_name: name,
                            party_legal_name: requestingUnitLegalName.identifier_legalname,
                            requesting_unit: true,
                            contracting_unit: false,
                            responsible_unit: false,
                            createdAt : new Date(),
                            updatedAt : new Date()
                        }).then(function(result){
                            return console.log("### requestingunits " + JSON.stringify(result))
                        });
                    } 
                });
            }else{
                var arrayRequestingunits = data.requestingunits.split('/');
                var code = arrayRequestingunits[0];
                var name = arrayRequestingunits[1];
                var requestingUnitLegalName = await db_conf.edca_db.oneOrNone('select identifier_legalname from parties p join roles r on p.id = r.parties_id where p.contractingprocess_id = $1 and r.requestingunit = true and p.partyid = $2 and p.name = $3 order by p.id', [data.contractingprocess_id,code,name]);
                await db.planning_party_unit.create({
                    contractingprocess_id: parseInt(data.contractingprocess_id, 10),
                    party_code: code,
                    party_name: name,
                    party_legal_name: requestingUnitLegalName.identifier_legalname,
                    requesting_unit: true,
                    contracting_unit: false,
                    responsible_unit: false,
                    createdAt : new Date(),
                    updatedAt : new Date()
                }).then(function(result){
                    return console.log("### requestingunits " + JSON.stringify(result))
                });
            }
        }
        if(data.contractingunits !== ""){
            if(Array.isArray(data.contractingunits)){
                data.contractingunits.forEach(async element =>{
                    if(element !== ""){
                        var arrayContractingunits = element.split('/');
                        var code = arrayContractingunits[0];
                        var name = arrayContractingunits[1];
                        var contractingUnitLegalName = await db_conf.edca_db.oneOrNone('select identifier_legalname from parties p join roles r on p.id = r.parties_id where p.contractingprocess_id = $1 and r.contractingunit = true and p.partyid = $2 and p.name = $3 order by p.id', [data.contractingprocess_id,code,name]);
                        await db.planning_party_unit.create({
                            contractingprocess_id: parseInt(data.contractingprocess_id, 10),
                            party_code: code,
                            party_name: name,
                            party_legal_name: contractingUnitLegalName.identifier_legalname,
                            requesting_unit: false,
                            contracting_unit: true,
                            responsible_unit: false,
                            createdAt : new Date(),
                            updatedAt : new Date()
                        }).then(function(result){
                            return console.log("### contractingunits " + JSON.stringify(result))
                        });
                    } 
                });
            }else{
                var arrayContractingunits = data.contractingunits.split('/');
                var code = arrayContractingunits[0];
                var name = arrayContractingunits[1];
                var contractingUnitLegalName = await db_conf.edca_db.oneOrNone('select identifier_legalname from parties p join roles r on p.id = r.parties_id where p.contractingprocess_id = $1 and r.contractingunit = true and p.partyid = $2 and p.name = $3 order by p.id', [data.contractingprocess_id,code,name]);
                await db.planning_party_unit.create({
                    contractingprocess_id: parseInt(data.contractingprocess_id, 10),
                    party_code: code,
                    party_name: name,
                    party_legal_name: contractingUnitLegalName.identifier_legalname,
                    requesting_unit: false,
                    contracting_unit: true,
                    responsible_unit: false,
                    createdAt : new Date(),
                    updatedAt : new Date()
                }).then(function(result){
                    return console.log("### contractingunits " + JSON.stringify(result))
                });
            }
        }
        if(data.responsibleunits !== ""){
            if(Array.isArray(data.responsibleunits)){                
                data.responsibleunits.forEach(async element =>{
                    if(element !== ""){
                        var arrayResponsibleunits = element.split('/');
                        var code = arrayResponsibleunits[0];
                        var name = arrayResponsibleunits[1];
                        var responsibleUnitLegalName = await db_conf.edca_db.oneOrNone('select identifier_legalname from parties p join roles r on p.id = r.parties_id where p.contractingprocess_id = $1 and r.responsibleunit = true and p.partyid = $2 and p.name = $3 order by p.id', [data.contractingprocess_id,code,name]);
                        await db.planning_party_unit.create({
                            contractingprocess_id: parseInt(data.contractingprocess_id, 10),
                            party_code: code,
                            party_name: name,
                            party_legal_name: responsibleUnitLegalName.identifier_legalname,
                            requesting_unit: false,
                            contracting_unit: false,
                            responsible_unit: true,
                            createdAt : new Date(),
                            updatedAt : new Date()
                        }).then(function(result){
                            return console.log("### responsibleunits " + JSON.stringify(result))
                        });
                    } 
                });
            }else{
                var arrayResponsibleunits = data.responsibleunits.split('/');
                var code = arrayResponsibleunits[0];
                var name = arrayResponsibleunits[1];
                var responsibleUnitLegalName = await db_conf.edca_db.oneOrNone('select identifier_legalname from parties p join roles r on p.id = r.parties_id where p.contractingprocess_id = $1 and r.responsibleunit = true and p.partyid = $2 and p.name = $3 order by p.id', [data.contractingprocess_id,code,name]);
                await db.planning_party_unit.create({
                    contractingprocess_id: parseInt(data.contractingprocess_id, 10),
                    party_code: code,
                    party_name: name,
                    party_legal_name: responsibleUnitLegalName.identifier_legalname,
                    requesting_unit: false,
                    contracting_unit: false,
                    responsible_unit: true,
                    createdAt : new Date(),
                    updatedAt : new Date()
                }).then(function(result){
                    return console.log("### responsibleunits " + JSON.stringify(result))
                });
            }
        }
        return true;
    }
};