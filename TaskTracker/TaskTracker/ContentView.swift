import SwiftUI

struct ContentView: View {
    @State private var tasks = [Task]()
    @State private var newTaskTitle = ""
    @State private var taskDueDate = Date()
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasks"),
           let storedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = storedTasks
        }
    }
    
    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: "tasks")
        }
    }
    
    private func addTask() {
        let newTask = Task(title: newTaskTitle, isCompleted: false, date: taskDueDate)
        tasks.append(newTask)
        saveTasks()
        newTaskTitle = ""
    }
    
    private func toggleTaskCompletion(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    private func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        saveTasks()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Enter a new task...", text: $newTaskTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addTask) {
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blue)
                    }
                    .disabled(newTaskTitle.isEmpty)
                }
                .padding()
                
                List {
                    ForEach(tasks) { task in
                        HStack {
                            Button(action: {
                                toggleTaskCompletion(task: task)
                            }){
                                Image(systemName: task.isCompleted ? "checkmark.square" : "square")
                                Text(task.title).strikethrough(task.isCompleted, color: .gray)
                            }
                        }
                        .padding()
                    }
                    .onDelete(perform: deleteTask)
                }
            }
            .onAppear(perform: loadTasks)
            .navigationTitle("To do List")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
