import { ethers } from "ethers";
import { useEffect, useState } from "react";


export interface Clan {
    id: number;
    name: string;
    leader: string;
    members: string[];
    lastVoteTime: number;
    lastVoteEndTime: number;
}
  
interface ClanInfoProps {
    clan?: Clan | null;
    contract : any
  }

interface  VoteForLeader {
    id : number,
}

const ClanInfo: React.FC<ClanInfoProps> = ({ clan, contract}) => {

    const [newClanName, setNewClanName] = useState('');
    const [votes, setVotes] = useState([]);

    const handleCreateClan = async () => {
        try {
            if(!newClanName) return;
            const data = await contract.createClan(newClanName, { value: ethers.parseEther("0.0001")});
            console.log(data);
            
        } catch (error) {
            console.log(error);
            
        }
    };
    // console.log(clan);
    useEffect(() => {
        async function getInfoAboutClan(){
            if(!clan) return;
            try {
                const info = await contract.getClanDetails(clan.id);
                const [, , , idsVotes, currentVoteId, , ] = info;
                if(idsVotes.length == 0 && !currentVoteId) return;
                const votesData = new Map<number, VoteForLeader>();
                for (const voteId of idsVotes) {
                  const voteData = await contract.getVoteDetails(clan.id, voteId);
                  votesData.set(voteId, voteData);
                }
                
                console.log(votesData);
                
                
                
                
            } catch (error) {
                console.log(error);
            }
        }
        if(!clan) return;
        getInfoAboutClan();
    }, [clan])
    return (
      <div className="p-4">
        {clan ? (
          <>
            <h2 className="text-xl font-bold mb-4">{clan.name}</h2>
            <p><strong>Líder:</strong> {clan.leader}</p>
            <p><strong>Miembros:</strong></p>
            <ul>
              {clan.members.map((member, index) => (
                <li key={index}>{member}</li>
              ))}
            </ul>
          </>
        ) : (
          <div>
            <h2 className="text-xl font-bold mb-4">Crear un nuevo clan</h2>
            <input
              type="text"
              value={newClanName}
              onChange={(e) => setNewClanName(e.target.value)}
              placeholder="Nombre del nuevo clan"
              className="p-2 border border-gray-300 rounded mb-2 w-full text-black"
            />
            <button
              onClick={handleCreateClan}
              className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-gray-200 hover:text-black"
            >
              Crear Clan
            </button>
          </div>
        )}
      </div>
    );
}

export default ClanInfo;